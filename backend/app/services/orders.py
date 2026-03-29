from __future__ import annotations

from datetime import date, timedelta

from fastapi import HTTPException
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models import Order, Product, ProductionTask
from app.schemas import OrderCreate
from app.services.production import create_production_tasks_for_order

ORDER_STATUS_FLOW = [
    "placed",
    "paid",
    "accepted",
    "in_production",
    "ready",
    "delivered",
    "archived",
]


def create_order(db: Session, payload: OrderCreate) -> Order:
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

    for _ in range(5):
        order = Order(
            order_code=_generate_order_code(db, date.today()),
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
        try:
            db.commit()
            db.refresh(order)
            return order
        except IntegrityError:
            db.rollback()

    raise HTTPException(status_code=500, detail="Failed to generate unique order code")


def get_orders_by_client(
    db: Session,
    client_id: int,
    order_code: str | None = None,
) -> list[Order]:
    query = db.query(Order).filter(Order.client_id == client_id)
    if order_code:
        query = query.filter(Order.order_code.like(f"{_normalize_order_code(order_code)}%"))
    return query.order_by(Order.created_at.desc()).all()


def get_orders_by_franchise(
    db: Session,
    franchise_id: int,
    order_code: str | None = None,
) -> list[Order]:
    query = db.query(Order).filter(Order.franchise_id == franchise_id)
    if order_code:
        query = query.filter(Order.order_code.like(f"{_normalize_order_code(order_code)}%"))
    return query.order_by(Order.created_at.desc()).all()


def update_order_status(
    db: Session,
    *,
    order_id: int,
    new_status: str,
    actor_user_id: int | None = None,
) -> tuple[Order, list[ProductionTask]]:
    if new_status not in ORDER_STATUS_FLOW:
        raise HTTPException(status_code=400, detail="Invalid order status")

    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    if not _can_transition(order.status, new_status):
        raise HTTPException(status_code=400, detail="Invalid order status transition")

    order.status = new_status
    order.tracking_stage = new_status

    tasks: list[ProductionTask] = []
    if new_status == "in_production":
        tasks = create_production_tasks_for_order(
            db,
            order=order,
            created_by=actor_user_id,
        )
        if tasks:
            order.tracking_stage = tasks[0].operation_stage

    db.commit()
    db.refresh(order)
    return order, tasks


def _can_transition(current_status: str, new_status: str) -> bool:
    if current_status == new_status:
        return True

    allowed_transitions = {
        "placed": {"paid", "accepted"},
        "paid": {"accepted"},
        "accepted": {"in_production"},
        "in_production": {"ready"},
        "ready": {"delivered"},
        "delivered": {"archived"},
        "archived": set(),
    }
    return new_status in allowed_transitions.get(current_status, set())


def _generate_order_code(db: Session, code_date: date) -> str:
    prefix = f"AV-{code_date.strftime('%Y%m%d')}-"
    latest = (
        db.query(Order.order_code)
        .filter(Order.order_code.like(f"{prefix}%"))
        .order_by(Order.order_code.desc())
        .first()
    )

    sequence = 1
    if latest and latest[0]:
        suffix = latest[0].split("-")[-1]
        if suffix.isdigit():
            sequence = int(suffix) + 1

    return f"{prefix}{sequence:04d}"


def _normalize_order_code(raw: str) -> str:
    return raw.strip().upper()
