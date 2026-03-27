# AVISHU Superapp Backend (MVP)

FastAPI + SQLite backend built from the contract in `../contracts/system_contract.docx`.

## Architecture Summary
- Single FastAPI service (no microservices).
- SQLAlchemy models for contract entities: `User`, `Product`, `Order`, `ProductionTask`.
- Supabase Auth for `POST /auth/login` and bearer token validation.
- WebSocket realtime channel at `GET /ws` (role-based channels).

## Contract Routes Implemented
- `POST /auth/login`
- `GET /products`
- `POST /orders`
- `GET /orders/client/{id}`
- `GET /orders/franchise/{id}`
- `PATCH /orders/{id}/status`
- `GET /production/tasks/{franchiseId}`
- `PATCH /production/tasks/{taskId}/complete`

## Status Lifecycle
- Order: `placed -> accepted -> in_production -> ready`
- ProductionTask: `queued -> active -> completed`

## Realtime Strategy
- `client:{user_id}` channel: order status updates.
- `franchise:{franchise_id}` channel: new orders + order status updates.
- `production:{franchise_id}` channel: production task updates.

## Run
1. Create and activate venv.
2. Install deps:
```bash
pip install -r requirements.txt
```
3. Configure env:
```bash
copy .env.example .env
```
4. Fill Supabase values in `.env`:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY` (for optional seed sync to Supabase Auth users)
5. Seed demo data:
```bash
python seed_demo.py
```
6. Start backend:
```bash
uvicorn app.main:app --reload --port 8000
```

## Demo Users
- `client@avishu.com / demo123`
- `franchisee@avishu.com / demo123`
- `production@avishu.com / demo123`
- These users must exist in Supabase Auth (seed script creates them when service role key is provided).

## WebSocket Usage
- Client: `/ws?role=client&user_id=<client_id>`
- Franchisee: `/ws?role=franchisee&franchise_id=<franchise_id>`
- Production: `/ws?role=production&franchise_id=<franchise_id>`

## API Verification Checklist
- [ ] Login works for all three roles.
- [ ] `GET /products` returns active products.
- [ ] Client creates order via `POST /orders`.
- [ ] Franchisee sees order via `GET /orders/franchise/{id}` and websocket event.
- [ ] Production sees task via `GET /production/tasks/{franchiseId}` and websocket event.
- [ ] Franchisee moves order to `accepted`, then `in_production`.
- [ ] Production completes task via `PATCH /production/tasks/{taskId}/complete`.
- [ ] Client receives realtime `ready` status update.

## Tests
Run backend tests:
```bash
pytest -q
```
