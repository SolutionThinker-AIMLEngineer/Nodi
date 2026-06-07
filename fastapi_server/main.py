import json
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from typing import Dict

app = FastAPI()

class ConnectionManager:
    def __init__(self):
        # Store connections as {client_id: websocket}
        self.active_connections: Dict[int, WebSocket] = {}

    async def connect(self, client_id: int, websocket: WebSocket):
        await websocket.accept()
        self.active_connections[client_id] = websocket
        print(f"Client #{client_id} connected. Online: {list(self.active_connections.keys())}")

    def disconnect(self, client_id: int):
        if client_id in self.active_connections:
            del self.active_connections[client_id]
            print(f"Client #{client_id} disconnected. Online: {list(self.active_connections.keys())}")

    async def send_to_client(self, target_id: int, message: dict) -> bool:
        if target_id in self.active_connections:
            await self.active_connections[target_id].send_text(json.dumps(message))
            return True
        return False

    def get_online_clients(self) -> list:
        return list(self.active_connections.keys())

manager = ConnectionManager()

@app.websocket("/ws/{client_id}")
async def websocket_endpoint(websocket: WebSocket, client_id: int):
    await manager.connect(client_id, websocket)

    # Notify the client that they connected successfully
    await websocket.send_text(json.dumps({
        "status": "connected",
        "your_id": client_id,
        "online_clients": manager.get_online_clients()
    }))

    # Notify all others that a new client joined
    for cid, conn in manager.active_connections.items():
        if cid != client_id:
            await conn.send_text(json.dumps({
                "status": "user_joined",
                "client_id": client_id,
                "online_clients": manager.get_online_clients()
            }))

    try:
        while True:
            raw = await websocket.receive_text()
            data = json.loads(raw)

            sender_id   = data.get("from")       # who is sending
            target_id   = data.get("to")         # who to deliver to
            message     = data.get("message", "")
            timestamp   = data.get("timestamp", "")

            print(f"Client #{sender_id} → Client #{target_id} [{timestamp}]: {message}")

            if target_id is None:
                # No target specified, send error back
                await websocket.send_text(json.dumps({
                    "status": "error",
                    "message": "No target client specified. Include 'to' field."
                }))
                continue

            # Forward message to target client
            delivered = await manager.send_to_client(int(target_id), {
                "status": "message",
                "from": sender_id,
                "message": message,
                "timestamp": timestamp
            })

            # Notify sender of delivery status
            await websocket.send_text(json.dumps({
                "status": "delivered" if delivered else "failed",
                "to": target_id,
                "message": message if delivered else f"Client #{target_id} is not online."
            }))

    except WebSocketDisconnect:
        manager.disconnect(client_id)

        # Notify remaining clients
        for cid, conn in manager.active_connections.items():
            await conn.send_text(json.dumps({
                "status": "user_left",
                "client_id": client_id,
                "online_clients": manager.get_online_clients()
            }))

@app.get("/")
async def root():
    return {"message": "WebSocket chat broker is running"}

@app.get("/clients")
async def get_clients():
    return {"online_clients": manager.get_online_clients()}