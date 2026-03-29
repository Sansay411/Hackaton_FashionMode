from __future__ import annotations

from datetime import datetime

from sqlalchemy import inspect, text

from fastapi import FastAPI, WebSocket, WebSocketDisconnect

from app.config import settings
from app.database import Base, engine
from app.realtime import manager
from app.routers.auth import router as auth_router
from app.routers.orders import router as orders_router
from app.routers.products import router as products_router
from app.routers.production import router as production_router
from app.routers.users import router as users_router

app = FastAPI(title=settings.app_name, debug=settings.debug)

app.include_router(auth_router)
app.include_router(products_router)
app.include_router(orders_router)
app.include_router(production_router)
app.include_router(users_router)


def _ensure_sqlite_schema() -> None:
    if not settings.database_url.startswith("sqlite"):
        return

    with engine.begin() as connection:
        inspector = inspect(connection)
        if inspector.has_table("orders"):
            order_columns = {
                column["name"] for column in inspector.get_columns("orders")
            }
            if "order_code" not in order_columns:
                connection.execute(
                    text("ALTER TABLE orders ADD COLUMN order_code VARCHAR(32)")
                )

            rows = connection.execute(
                text(
                    "SELECT id, created_at, order_code "
                    "FROM orders ORDER BY created_at ASC, id ASC"
                )
            ).fetchall()
            day_counters: dict[str, int] = {}
            used_codes: set[str] = set()

            for row in rows:
                existing_code = row.order_code
                if existing_code:
                    used_codes.add(existing_code)
                    prefix = existing_code[:13]
                    suffix = existing_code.split("-")[-1]
                    if suffix.isdigit():
                        day_counters[prefix] = max(
                            day_counters.get(prefix, 0),
                            int(suffix),
                        )
                    continue

                raw_created_at = row.created_at
                created_at = raw_created_at
                if isinstance(raw_created_at, str):
                    created_at = datetime.fromisoformat(
                        raw_created_at.replace("Z", "+00:00")
                    )

                prefix = f"AV-{created_at.strftime('%Y%m%d')}"
                next_number = day_counters.get(prefix, 0) + 1
                code = f"{prefix}-{next_number:04d}"
                while code in used_codes:
                    next_number += 1
                    code = f"{prefix}-{next_number:04d}"

                day_counters[prefix] = next_number
                used_codes.add(code)
                connection.execute(
                    text("UPDATE orders SET order_code = :code WHERE id = :id"),
                    {"code": code, "id": row.id},
                )

            connection.execute(
                text(
                    "CREATE UNIQUE INDEX IF NOT EXISTS ix_orders_order_code "
                    "ON orders(order_code)"
                )
            )

        inspector = inspect(connection)
        if inspector.has_table("users"):
            user_columns = {
                column["name"] for column in inspector.get_columns("users")
            }
            if "production_type" not in user_columns:
                connection.execute(
                    text("ALTER TABLE users ADD COLUMN production_type VARCHAR(32)")
                )
            if "specialization" not in user_columns:
                connection.execute(
                    text("ALTER TABLE users ADD COLUMN specialization VARCHAR(32)")
                )

        inspector = inspect(connection)
        if not inspector.has_table("production_tasks"):
            return

        task_columns = {
            column["name"] for column in inspector.get_columns("production_tasks")
        }
        if "order_code" not in task_columns:
            connection.execute(
                text("ALTER TABLE production_tasks ADD COLUMN order_code VARCHAR(32)")
            )
            connection.execute(
                text(
                    "UPDATE production_tasks "
                    "SET order_code = (SELECT orders.order_code FROM orders WHERE orders.id = production_tasks.order_id) "
                    "WHERE order_code IS NULL"
                )
            )
            connection.execute(
                text(
                    "CREATE INDEX IF NOT EXISTS ix_production_tasks_order_code "
                    "ON production_tasks(order_code)"
                )
            )
            inspector = inspect(connection)
            task_columns = {
                column["name"] for column in inspector.get_columns("production_tasks")
            }
        if "priority" not in task_columns:
            connection.execute(
                text(
                    "ALTER TABLE production_tasks "
                    "ADD COLUMN priority VARCHAR(16) NOT NULL DEFAULT 'medium'"
                )
            )
            connection.execute(
                text(
                    "CREATE INDEX IF NOT EXISTS ix_production_tasks_priority "
                    "ON production_tasks(priority)"
                )
            )
            inspector = inspect(connection)
            task_columns = {
                column["name"] for column in inspector.get_columns("production_tasks")
            }
        required_columns = {
            "order_code",
            "priority",
            "assigned_to",
            "assigned_to_name",
            "created_by",
            "started_at",
            "completed_at",
            "updated_at",
        }
        needs_rebuild = not required_columns.issubset(task_columns)

        for index in inspector.get_indexes("production_tasks"):
            if index["name"] == "ix_production_tasks_order_id" and index.get("unique"):
                needs_rebuild = True

        if not needs_rebuild:
            return

        connection.execute(text("DROP TABLE IF EXISTS production_tasks_new"))
        connection.execute(
            text(
                """
                CREATE TABLE production_tasks_new (
                    id INTEGER NOT NULL PRIMARY KEY,
                    order_id INTEGER NOT NULL,
                    order_code VARCHAR(32) NOT NULL,
                    franchise_id INTEGER NOT NULL,
                    title VARCHAR(255) NOT NULL,
                    priority VARCHAR(16) NOT NULL,
                    status VARCHAR(32) NOT NULL,
                    operation_stage VARCHAR(32) NOT NULL,
                    assigned_to INTEGER,
                    assigned_to_name VARCHAR(255),
                    created_by INTEGER,
                    started_at DATETIME,
                    completed_at DATETIME,
                    created_at DATETIME NOT NULL,
                    updated_at DATETIME NOT NULL
                )
                """
            )
        )
        connection.execute(
            text(
                """
                INSERT INTO production_tasks_new (
                    id, order_id, order_code, franchise_id, title, status, operation_stage,
                    priority, assigned_to, assigned_to_name, created_by, started_at,
                    completed_at, created_at, updated_at
                )
                SELECT
                    id,
                    order_id,
                    COALESCE(
                        order_code,
                        (SELECT orders.order_code FROM orders WHERE orders.id = production_tasks.order_id)
                    ),
                    franchise_id,
                    title,
                    CASE status
                        WHEN 'active' THEN 'in_progress'
                        ELSE status
                    END,
                    CASE
                        WHEN operation_stage IN ('queued', 'active', 'completed')
                            THEN 'qc'
                        ELSE operation_stage
                    END,
                    'medium',
                    NULL,
                    NULL,
                    NULL,
                    CASE WHEN status = 'active' THEN created_at ELSE NULL END,
                    CASE WHEN status = 'completed' THEN created_at ELSE NULL END,
                    created_at,
                    created_at
                FROM production_tasks
                """
            )
        )
        connection.execute(text("DROP TABLE production_tasks"))
        connection.execute(text("ALTER TABLE production_tasks_new RENAME TO production_tasks"))
        connection.execute(
            text(
                "CREATE INDEX IF NOT EXISTS ix_production_tasks_order_id "
                "ON production_tasks(order_id)"
            )
        )
        connection.execute(
            text(
                "CREATE INDEX IF NOT EXISTS ix_production_tasks_franchise_id "
                "ON production_tasks(franchise_id)"
            )
        )
        connection.execute(
            text(
                "CREATE INDEX IF NOT EXISTS ix_production_tasks_status "
                "ON production_tasks(status)"
            )
        )
        connection.execute(
            text(
                "CREATE INDEX IF NOT EXISTS ix_production_tasks_assigned_to "
                "ON production_tasks(assigned_to)"
            )
        )
        connection.execute(
            text(
                "CREATE INDEX IF NOT EXISTS ix_production_tasks_created_by "
                "ON production_tasks(created_by)"
            )
        )
        connection.execute(
            text(
                "CREATE INDEX IF NOT EXISTS ix_production_tasks_priority "
                "ON production_tasks(priority)"
            )
        )
        connection.execute(
            text(
                "CREATE INDEX IF NOT EXISTS ix_production_tasks_order_code "
                "ON production_tasks(order_code)"
            )
        )


@app.on_event("startup")
def on_startup() -> None:
    Base.metadata.create_all(bind=engine)
    _ensure_sqlite_schema()


@app.websocket("/ws")
async def websocket_endpoint(
    websocket: WebSocket,
    role: str,
    user_id: int | None = None,
    franchise_id: int | None = None,
) -> None:
    if role == "client":
        if user_id is None:
            await websocket.close(code=1008)
            return
        channel = f"client:{user_id}"
    elif role == "franchisee":
        if franchise_id is None:
            await websocket.close(code=1008)
            return
        channel = f"franchise:{franchise_id}"
    elif role == "production":
        if franchise_id is None:
            await websocket.close(code=1008)
            return
        channel = f"production:{franchise_id}"
    else:
        await websocket.close(code=1008)
        return

    await manager.connect(channel, websocket)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(channel, websocket)
