from __future__ import annotations

from collections import defaultdict

from fastapi import WebSocket


class RealtimeManager:
    def __init__(self) -> None:
        self.channels: dict[str, set[WebSocket]] = defaultdict(set)

    async def connect(self, channel: str, websocket: WebSocket) -> None:
        await websocket.accept()
        self.channels[channel].add(websocket)

    def disconnect(self, channel: str, websocket: WebSocket) -> None:
        if channel in self.channels:
            self.channels[channel].discard(websocket)
            if not self.channels[channel]:
                del self.channels[channel]

    async def broadcast(self, channel: str, event: str, data: dict) -> None:
        sockets = list(self.channels.get(channel, set()))
        for socket in sockets:
            try:
                await socket.send_json({"event": event, "data": data})
            except Exception:
                self.disconnect(channel, socket)


manager = RealtimeManager()

