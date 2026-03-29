from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.auth import require_production_type, require_role
from app.database import get_db
from app.models import ProductionTask, User
from app.realtime import manager
from app.schemas import (
    ProductionTaskAssignRequest,
    ProductionTaskOut,
    ProductionWorkerCreateRequest,
    ProductionWorkerDeleteResponse,
    UserOut,
)
from app.services.production import (
    assign_task,
    complete_task,
    create_worker_account,
    delete_worker_account,
    get_tasks_for_user,
    get_workers_by_franchise,
    start_task,
)

router = APIRouter(prefix="/production", tags=["production"])


def _task_data(task: ProductionTask) -> dict:
    return ProductionTaskOut.model_validate(task).model_dump(mode="json")


async def _broadcast_task_change(task: ProductionTask, order) -> None:
    task_data = _task_data(task)
    await manager.broadcast(
        f"production:{task.franchise_id}",
        "production_task_updated",
        task_data,
    )
    if task.assigned_to is not None:
        await manager.broadcast(
            f"production:{task.franchise_id}",
            "worker_task_updated",
            {"task_id": task.id, "assigned_to": task.assigned_to},
        )
    await manager.broadcast(
        f"franchise:{task.franchise_id}",
        "order_status_updated",
        {
            "order_id": order.id,
            "order_code": order.order_code,
            "status": order.status,
            "tracking_stage": order.tracking_stage,
        },
    )
    await manager.broadcast(
        f"client:{order.client_id}",
        "order_status_updated",
        {
            "order_id": order.id,
            "order_code": order.order_code,
            "status": order.status,
            "tracking_stage": order.tracking_stage,
        },
    )


@router.get("/tasks/{franchiseId}", response_model=list[ProductionTaskOut])
def get_production_queue(
    franchiseId: int,
    status: str | None = Query(default=None),
    worker_id: int | None = Query(default=None),
    specialization: str | None = Query(default=None),
    priority: str | None = Query(default=None),
    order_code: str | None = Query(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role("production")),
) -> list[ProductionTaskOut]:
    if current_user.franchise_id != franchiseId:
        raise HTTPException(status_code=403, detail="Can only access own franchise queue")
    tasks = get_tasks_for_user(
        db=db,
        franchise_id=franchiseId,
        current_user=current_user,
        status=status,
        worker_id=worker_id,
        specialization=specialization,
        priority=priority,
        order_code=order_code,
    )
    return [ProductionTaskOut.model_validate(item) for item in tasks]


@router.get("/workers/{franchiseId}", response_model=list[UserOut])
def get_production_workers(
    franchiseId: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_production_type("manager")),
) -> list[UserOut]:
    if current_user.franchise_id != franchiseId:
        raise HTTPException(status_code=403, detail="Can only access own franchise workers")
    workers = get_workers_by_franchise(db=db, franchise_id=franchiseId)
    return [UserOut.model_validate(item) for item in workers]


@router.post("/workers", response_model=UserOut)
def create_production_worker(
    payload: ProductionWorkerCreateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_production_type("manager")),
) -> UserOut:
    worker = create_worker_account(
        db=db,
        manager_user=current_user,
        email=payload.email,
        password=payload.password,
        full_name=payload.full_name,
        specialization=payload.specialization,
    )
    return UserOut.model_validate(worker)


@router.delete("/workers/{workerId}", response_model=ProductionWorkerDeleteResponse)
def delete_production_worker(
    workerId: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_production_type("manager")),
) -> ProductionWorkerDeleteResponse:
    delete_worker_account(
        db=db,
        manager_user=current_user,
        worker_id=workerId,
    )
    return ProductionWorkerDeleteResponse(success=True)


@router.patch("/tasks/{taskId}/assign", response_model=ProductionTaskOut)
async def assign_production_task(
    taskId: int,
    payload: ProductionTaskAssignRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_production_type("manager")),
) -> ProductionTaskOut:
    task, order = assign_task(
        db=db,
        task_id=taskId,
        manager_user=current_user,
        worker_id=payload.worker_id,
    )
    await _broadcast_task_change(task, order)
    return ProductionTaskOut.model_validate(task)


@router.patch("/tasks/{taskId}/start", response_model=ProductionTaskOut)
async def start_production_task(
    taskId: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_production_type("worker")),
) -> ProductionTaskOut:
    task, order = start_task(
        db=db,
        task_id=taskId,
        worker_user=current_user,
    )
    await _broadcast_task_change(task, order)
    return ProductionTaskOut.model_validate(task)


@router.patch("/tasks/{taskId}/complete", response_model=ProductionTaskOut)
async def complete_production_task(
    taskId: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_production_type("worker")),
) -> ProductionTaskOut:
    existing = db.query(ProductionTask).filter(ProductionTask.id == taskId).first()
    if not existing:
        raise HTTPException(status_code=404, detail="Production task not found")
    if current_user.franchise_id != existing.franchise_id:
        raise HTTPException(status_code=403, detail="Can only complete own franchise tasks")

    task, order = complete_task(
        db=db,
        task_id=taskId,
        worker_user=current_user,
    )
    await _broadcast_task_change(task, order)
    return ProductionTaskOut.model_validate(task)
