from __future__ import annotations

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.auth import create_auth_user
from app.models import Order, ProductionTask, User, utc_now

PRODUCTION_STAGES = ["cutting", "sewing", "finishing", "qc"]
TASK_STATUS_FLOW = ["queued", "assigned", "in_progress", "completed"]


def create_production_tasks_for_order(
    db: Session,
    *,
    order: Order,
    created_by: int | None,
) -> list[ProductionTask]:
    existing = (
        db.query(ProductionTask)
        .filter(ProductionTask.order_id == order.id)
        .order_by(ProductionTask.id.asc())
        .all()
    )
    if existing:
        return existing

    tasks: list[ProductionTask] = []
    for stage in PRODUCTION_STAGES:
        task = ProductionTask(
            order_id=order.id,
            order_code=order.order_code,
            franchise_id=order.franchise_id,
            title=f"{order.product_title} · {stage.upper()}",
            priority=_resolve_priority(order),
            operation_stage=stage,
            status="queued",
            created_by=created_by,
        )
        db.add(task)
        tasks.append(task)

    db.flush()
    db.commit()
    for task in tasks:
        db.refresh(task)
    return tasks


def get_tasks_for_user(
    db: Session,
    *,
    franchise_id: int,
    current_user: User,
    status: str | None = None,
    worker_id: int | None = None,
    specialization: str | None = None,
    priority: str | None = None,
    order_code: str | None = None,
) -> list[ProductionTask]:
    query = (
        db.query(ProductionTask)
        .filter(ProductionTask.franchise_id == franchise_id)
        .order_by(ProductionTask.created_at.desc(), ProductionTask.id.desc())
    )

    if current_user.production_type == "worker":
        query = query.filter(ProductionTask.assigned_to == current_user.id)
    elif worker_id is not None:
        query = query.filter(ProductionTask.assigned_to == worker_id)

    if status:
        query = query.filter(ProductionTask.status == status)
    if specialization:
        query = query.filter(ProductionTask.operation_stage == specialization)
    if priority:
        query = query.filter(ProductionTask.priority == priority)
    if order_code:
        query = query.filter(ProductionTask.order_code.like(f"{order_code.strip().upper()}%"))

    return query.all()


def get_workers_by_franchise(db: Session, *, franchise_id: int) -> list[User]:
    return (
        db.query(User)
        .filter(
            User.role == "production",
            User.production_type == "worker",
            User.franchise_id == franchise_id,
        )
        .order_by(User.full_name.asc())
        .all()
    )


def create_worker_account(
    db: Session,
    *,
    manager_user: User,
    email: str,
    password: str,
    full_name: str,
    specialization: str,
) -> User:
    normalized_email = email.strip().lower()
    normalized_name = full_name.strip()
    normalized_password = password.strip()
    normalized_specialization = specialization.strip().lower()

    if not manager_user.franchise_id:
        raise HTTPException(status_code=400, detail="Manager franchise is not configured")
    if not normalized_name:
        raise HTTPException(status_code=422, detail="Full name is required")
    if "@" not in normalized_email or "." not in normalized_email:
        raise HTTPException(status_code=422, detail="Valid email is required")
    if len(normalized_password) < 6:
        raise HTTPException(status_code=422, detail="Password must be at least 6 characters")
    if normalized_specialization not in PRODUCTION_STAGES:
        raise HTTPException(status_code=422, detail="Unsupported worker specialization")

    existing = db.query(User).filter(User.email == normalized_email).first()
    if existing:
        raise HTTPException(status_code=409, detail="User with this email already exists")

    create_auth_user(email=normalized_email, password=normalized_password)

    worker = User(
        email=normalized_email,
        full_name=normalized_name,
        role="production",
        production_type="worker",
        specialization=normalized_specialization,
        franchise_id=manager_user.franchise_id,
        password=normalized_password,
    )
    db.add(worker)
    db.commit()
    db.refresh(worker)
    return worker


def delete_worker_account(
    db: Session,
    *,
    manager_user: User,
    worker_id: int,
) -> None:
    worker = db.query(User).filter(User.id == worker_id).first()
    if not worker:
        raise HTTPException(status_code=404, detail="Production worker not found")
    if worker.role != "production" or worker.production_type != "worker":
        raise HTTPException(status_code=400, detail="Target user is not a production worker")
    if worker.franchise_id != manager_user.franchise_id:
        raise HTTPException(status_code=403, detail="Can only delete own franchise workers")

    active_task = (
        db.query(ProductionTask)
        .filter(
            ProductionTask.assigned_to == worker.id,
            ProductionTask.status != "completed",
        )
        .first()
    )
    if active_task:
        raise HTTPException(
            status_code=409,
            detail="Cannot delete worker with active production tasks",
        )

    completed_tasks = (
        db.query(ProductionTask)
        .filter(ProductionTask.assigned_to == worker.id)
        .all()
    )
    for task in completed_tasks:
        task.assigned_to = None
        task.updated_at = utc_now()

    db.delete(worker)
    db.commit()


def assign_task(
    db: Session,
    *,
    task_id: int,
    manager_user: User,
    worker_id: int,
) -> tuple[ProductionTask, Order]:
    task = db.query(ProductionTask).filter(ProductionTask.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Production task not found")
    if task.franchise_id != manager_user.franchise_id:
        raise HTTPException(status_code=403, detail="Can only assign own franchise tasks")

    worker = db.query(User).filter(User.id == worker_id).first()
    if not worker:
        raise HTTPException(status_code=404, detail="Production worker not found")
    if worker.role != "production" or worker.production_type != "worker":
        raise HTTPException(status_code=400, detail="Target user is not a production worker")
    if worker.franchise_id != manager_user.franchise_id:
        raise HTTPException(status_code=403, detail="Can only assign own franchise workers")
    if task.status not in {"queued", "assigned"}:
        raise HTTPException(status_code=400, detail="Only queued or assigned task can be reassigned")

    order = db.query(Order).filter(Order.id == task.order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order for task not found")

    task.assigned_to = worker.id
    task.assigned_to_name = worker.full_name
    task.status = "assigned"
    task.updated_at = utc_now()
    order.tracking_stage = task.operation_stage

    db.commit()
    db.refresh(task)
    db.refresh(order)
    return task, order


def start_task(
    db: Session,
    *,
    task_id: int,
    worker_user: User,
) -> tuple[ProductionTask, Order]:
    task = db.query(ProductionTask).filter(ProductionTask.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Production task not found")
    if task.assigned_to != worker_user.id:
        raise HTTPException(status_code=403, detail="Worker can start only own assigned task")
    if task.status != "assigned":
        raise HTTPException(status_code=400, detail="Task must be assigned before start")

    order = db.query(Order).filter(Order.id == task.order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order for task not found")
    if order.status != "in_production":
        raise HTTPException(status_code=400, detail="Order must be in_production before task start")

    _ensure_previous_stages_completed(db, order_id=order.id, stage=task.operation_stage)

    task.status = "in_progress"
    task.started_at = utc_now()
    task.updated_at = utc_now()
    order.tracking_stage = task.operation_stage

    db.commit()
    db.refresh(task)
    db.refresh(order)
    return task, order


def complete_task(
    db: Session,
    *,
    task_id: int,
    worker_user: User,
) -> tuple[ProductionTask, Order]:
    task = db.query(ProductionTask).filter(ProductionTask.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Production task not found")
    if task.assigned_to != worker_user.id:
        raise HTTPException(status_code=403, detail="Worker can complete only own task")
    if task.status not in TASK_STATUS_FLOW:
        raise HTTPException(status_code=400, detail="Invalid production task status")
    if task.status != "in_progress":
        raise HTTPException(status_code=400, detail="Task must be in_progress before completion")

    order = db.query(Order).filter(Order.id == task.order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order for task not found")
    if order.status != "in_production":
        raise HTTPException(status_code=400, detail="Order must be in_production before completion")

    task.status = "completed"
    task.completed_at = utc_now()
    task.updated_at = utc_now()

    remaining = (
        db.query(ProductionTask)
        .filter(
            ProductionTask.order_id == order.id,
            ProductionTask.status != "completed",
            ProductionTask.id != task.id,
        )
        .order_by(ProductionTask.id.asc())
        .all()
    )

    if not remaining and task.operation_stage == PRODUCTION_STAGES[-1]:
        order.status = "ready"
        order.tracking_stage = "ready"
    else:
        next_task = _get_next_task(db, order_id=order.id)
        order.tracking_stage = next_task.operation_stage if next_task else task.operation_stage

    db.commit()
    db.refresh(task)
    db.refresh(order)
    return task, order


def _ensure_previous_stages_completed(db: Session, *, order_id: int, stage: str) -> None:
    target_index = PRODUCTION_STAGES.index(stage)
    required_stages = set(PRODUCTION_STAGES[:target_index])
    if not required_stages:
        return

    completed_stages = {
        task.operation_stage
        for task in db.query(ProductionTask)
        .filter(
            ProductionTask.order_id == order_id,
            ProductionTask.status == "completed",
        )
        .all()
    }
    missing = required_stages - completed_stages
    if missing:
        raise HTTPException(
            status_code=400,
            detail="Previous production stages must be completed first",
        )


def _get_next_task(db: Session, *, order_id: int) -> ProductionTask | None:
    tasks = (
        db.query(ProductionTask)
        .filter(ProductionTask.order_id == order_id)
        .order_by(ProductionTask.id.asc())
        .all()
    )
    for stage in PRODUCTION_STAGES:
        for task in tasks:
            if task.operation_stage == stage and task.status != "completed":
                return task
    return None


def _resolve_priority(order: Order) -> str:
    if order.order_type == "in_stock" or order.quantity >= 2:
        return "high"
    if order.order_type == "made_to_order":
        return "medium"
    return "low"
