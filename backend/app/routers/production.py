from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.auth import require_role
from app.database import get_db
from app.models import ProductionTask, User
from app.realtime import manager
from app.schemas import ProductionTaskOut
from app.services.production import complete_task, get_tasks_by_franchise

router = APIRouter(prefix="/production", tags=["production"])


def _task_data(task) -> dict:
    return ProductionTaskOut.model_validate(task).model_dump(mode="json")


@router.get("/tasks/{franchiseId}", response_model=list[ProductionTaskOut])
def get_production_queue(
    franchiseId: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role("production")),
) -> list[ProductionTaskOut]:
    if current_user.franchise_id != franchiseId:
        raise HTTPException(status_code=403, detail="Can only access own franchise queue")
    tasks = get_tasks_by_franchise(db=db, franchise_id=franchiseId)
    return [ProductionTaskOut.model_validate(item) for item in tasks]


@router.patch("/tasks/{taskId}/complete", response_model=ProductionTaskOut)
async def complete_production_task(
    taskId: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role("production")),
) -> ProductionTaskOut:
    existing = db.query(ProductionTask).filter(ProductionTask.id == taskId).first()
    if not existing:
        raise HTTPException(status_code=404, detail="Production task not found")
    if current_user.franchise_id != existing.franchise_id:
        raise HTTPException(status_code=403, detail="Can only complete own franchise tasks")

    task, order = complete_task(db=db, task_id=taskId)

    task_data = _task_data(task)
    await manager.broadcast(f"production:{task.franchise_id}", "production_task_updated", task_data)
    await manager.broadcast(
        f"franchise:{task.franchise_id}",
        "order_status_updated",
        {"order_id": order.id, "status": order.status},
    )
    await manager.broadcast(
        f"client:{order.client_id}",
        "order_status_updated",
        {"order_id": order.id, "status": order.status, "tracking_stage": order.tracking_stage},
    )
    return ProductionTaskOut.model_validate(task)
