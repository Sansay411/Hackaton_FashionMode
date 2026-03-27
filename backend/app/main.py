from __future__ import annotations

from fastapi import FastAPI, WebSocket, WebSocketDisconnect

from app.config import settings
from app.database import Base, engine
from app.realtime import manager
from app.routers.auth import router as auth_router
from app.routers.orders import router as orders_router
from app.routers.products import router as products_router
from app.routers.production import router as production_router

app = FastAPI(title=settings.app_name, debug=settings.debug)

app.include_router(auth_router)
app.include_router(products_router)
app.include_router(orders_router)
app.include_router(production_router)


@app.on_event("startup")
def on_startup() -> None:
    Base.metadata.create_all(bind=engine)


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
