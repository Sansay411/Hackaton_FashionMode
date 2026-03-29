# AVISHU Superapp Backend

Backend на FastAPI и SQLite.

## Что делает сервис

- авторизация
- каталог товаров
- создание и обновление заказов
- очередь производства
- назначение задач сотрудникам
- синхронизация статусов между ролями

## Запуск

Из корня проекта:

```bash
./scripts/run_demo.sh
```

Сброс данных:

```bash
./scripts/reset_demo.sh
```

Ручной запуск:

```bash
cd backend
python -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
python seed_demo.py
uvicorn app.main:app --host 127.0.0.1 --port 8000
```

## Основные маршруты

- `POST /auth/login`
- `POST /auth/register`
- `GET /products`
- `POST /orders`
- `GET /orders/client/{id}`
- `GET /orders/franchise/{id}`
- `PATCH /orders/{id}/status`
- `GET /production/tasks/{franchiseId}`
- `GET /production/workers/{franchiseId}`
- `PATCH /production/tasks/{taskId}/assign`
- `PATCH /production/tasks/{taskId}/start`
- `PATCH /production/tasks/{taskId}/complete`

## Проверка

```bash
cd backend
PYTHONPATH=. .venv/bin/pytest -q
```
