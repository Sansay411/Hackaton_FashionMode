from __future__ import annotations

from datetime import date, timedelta

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models import Order, Product, ProductionTask
from app.schemas import OrderCreate

ORDER_STATUS_FLOW = ["placed", "accepted", "in_production", "ready"]


def create_order(db: Session, payload: OrderCreate) -> tuple[Order, ProductionTask]:
    product = (
        db.query(Product)
        .filter(
            Product.id == payload.product_id,
            Product.is_active.is_(True),
        )
        .first()
    )
    if not product:
        raise HTTPException(status_code=404, detail="Product not found or inactive")

    ready_date = payload.selected_ready_date
    if ready_date is None:
        ready_date = date.today() + timedelta(days=product.default_ready_days)

    order = Order(
        client_id=payload.client_id,
        franchise_id=payload.franchise_id,
        product_id=payload.product_id,
        product_title=product.title,
        quantity=payload.quantity,
        order_type=payload.order_type,
        selected_ready_date=ready_date,
        status="placed",
        tracking_stage="placed",
        loyalty_progress=0,
    )
    db.add(order)
    db.flush()

    task = ProductionTask(
        order_id=order.id,
        franchise_id=order.franchise_id,
        title=product.title,
        status="queued",
        operation_stage="queued",
    )
    db.add(task)
    db.commit()
    db.refresh(order)
    db.refresh(task)
    return order, task


def get_orders_by_client(db: Session, client_id: int) -> list[Order]:
    return db.query(Order).filter(Order.client_id == client_id).order_by(Order.created_at.desc()).all()


def get_orders_by_franchise(db: Session, franchise_id: int) -> list[Order]:
    return (
        db.query(Order)
        .filter(Order.franchise_id == franchise_id)
        .order_by(Order.created_at.desc())
        .all()
    )


def update_order_status(db: Session, order_id: int, new_status: str) -> tuple[Order, ProductionTask | None]:
    if new_status not in ORDER_STATUS_FLOW:
        raise HTTPException(status_code=400, detail="Invalid order status")

    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    current_index = ORDER_STATUS_FLOW.index(order.status)
    target_index = ORDER_STATUS_FLOW.index(new_status)
    if target_index < current_index or target_index > current_index + 1:
        raise HTTPException(status_code=400, detail="Invalid order status transition")

    order.status = new_status
    order.tracking_stage = new_status

    task = db.query(ProductionTask).filter(ProductionTask.order_id == order.id).first()
    if task and new_status == "in_production" and task.status == "queued":
        task.status = "active"
        task.operation_stage = "active"

    db.commit()
    db.refresh(order)
    if task:
        db.refresh(task)
    return order, task

