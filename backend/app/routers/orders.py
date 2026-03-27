from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.auth import require_role
from app.database import get_db
from app.models import Order, User
from app.realtime import manager
from app.schemas import OrderCreate, OrderOut, OrderStatusUpdate
from app.services.orders import create_order, get_orders_by_client, get_orders_by_franchise, update_order_status

router = APIRouter(tags=["orders"])


def _order_data(order) -> dict:
    return OrderOut.model_validate(order).model_dump(mode="json")


@router.post("/orders", response_model=OrderOut)
async def create_new_order(
    payload: OrderCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role("client")),
) -> OrderOut:
    if payload.client_id != current_user.id:
        raise HTTPException(status_code=403, detail="client_id must match logged in client")

    order, task = create_order(db=db, payload=payload)
    order_data = _order_data(order)

    await manager.broadcast(f"franchise:{order.franchise_id}", "order_created", order_data)
    await manager.broadcast(f"production:{order.franchise_id}", "production_task_created", {"task_id": task.id})
    await manager.broadcast(f"client:{order.client_id}", "order_status_updated", order_data)
    return OrderOut.model_validate(order)


@router.get("/orders/client/{id}", response_model=list[OrderOut])
def get_client_orders(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role("client")),
) -> list[OrderOut]:
    if id != current_user.id:
        raise HTTPException(status_code=403, detail="Can only access own client orders")
    orders = get_orders_by_client(db=db, client_id=id)
    return [OrderOut.model_validate(item) for item in orders]


@router.get("/orders/franchise/{id}", response_model=list[OrderOut])
def get_franchise_orders(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role("franchisee")),
) -> list[OrderOut]:
    if current_user.franchise_id != id:
        raise HTTPException(status_code=403, detail="Can only access own franchise orders")
    orders = get_orders_by_franchise(db=db, franchise_id=id)
    return [OrderOut.model_validate(item) for item in orders]


@router.patch("/orders/{id}/status", response_model=OrderOut)
async def patch_order_status(
    id: int,
    payload: OrderStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role("franchisee")),
) -> OrderOut:
    existing = db.query(Order).filter(Order.id == id).first()
    if not existing:
        raise HTTPException(status_code=404, detail="Order not found")
    if current_user.franchise_id != existing.franchise_id:
        raise HTTPException(status_code=403, detail="Can only update own franchise orders")

    order, task = update_order_status(db=db, order_id=id, new_status=payload.status)

    order_data = _order_data(order)
    await manager.broadcast(f"franchise:{order.franchise_id}", "order_status_updated", order_data)
    await manager.broadcast(f"client:{order.client_id}", "order_status_updated", order_data)
    if task:
        await manager.broadcast(
            f"production:{order.franchise_id}",
            "production_task_updated",
            {"task_id": task.id, "status": task.status},
        )
    return OrderOut.model_validate(order)
