from __future__ import annotations

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models import Order, ProductionTask

TASK_STATUS_FLOW = ["queued", "active", "completed"]


def get_tasks_by_franchise(db: Session, franchise_id: int) -> list[ProductionTask]:
    return (
        db.query(ProductionTask)
        .filter(ProductionTask.franchise_id == franchise_id)
        .order_by(ProductionTask.created_at.desc())
        .all()
    )


def complete_task(db: Session, task_id: int) -> tuple[ProductionTask, Order]:
    task = db.query(ProductionTask).filter(ProductionTask.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Production task not found")

    if task.status not in TASK_STATUS_FLOW:
        raise HTTPException(status_code=400, detail="Invalid production task status")

    order = db.query(Order).filter(Order.id == task.order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order for task not found")

    if task.status == "completed":
        return task, order

    if task.status != "active":
        raise HTTPException(status_code=400, detail="Task must be active before completion")

    if order.status != "in_production":
        raise HTTPException(status_code=400, detail="Order must be in_production before completion")

    task.status = "completed"
    task.operation_stage = "completed"
    order.status = "ready"
    order.tracking_stage = "ready"

    db.commit()
    db.refresh(task)
    db.refresh(order)
    return task, order
