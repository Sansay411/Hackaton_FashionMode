from __future__ import annotations

from datetime import date, datetime

import httpx

from app.config import settings
from app.database import Base, SessionLocal, engine
from app.main import _ensure_sqlite_schema
from app.models import Order, Product, ProductionTask, User


def sync_supabase_users(users: list[dict[str, str]]) -> None:
    if not settings.supabase_url or not settings.supabase_service_role_key:
        print("Supabase admin sync skipped (SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY is missing).")
        return

    url = f"{settings.supabase_url.rstrip('/')}/auth/v1/admin/users"
    headers = {
        "apikey": settings.supabase_service_role_key,
        "Authorization": f"Bearer {settings.supabase_service_role_key}",
        "Content-Type": "application/json",
    }
    for user in users:
        try:
            response = httpx.post(
                url,
                headers=headers,
                json={
                    "email": user["email"],
                    "password": user["password"],
                    "email_confirm": True,
                },
                timeout=settings.supabase_timeout_seconds,
            )
        except httpx.HTTPError:
            print(f"Supabase sync error for {user['email']}: network/auth service issue.")
            continue

        if response.status_code in {200, 201}:
            print(f"Supabase user created: {user['email']}")
            continue

        body_text = response.text.lower()
        if "already" in body_text or "exists" in body_text:
            print(f"Supabase user exists: {user['email']}")
            continue

        print(f"Supabase sync warning for {user['email']}: {response.status_code}")


def _upsert_user(db, payload: dict[str, str | int | None]) -> User:
    user = db.query(User).filter(User.email == payload["email"]).first()
    if user is None:
        user = User(**payload)
        db.add(user)
        db.flush()
        return user

    for key, value in payload.items():
        setattr(user, key, value)
    db.flush()
    return user


def _upsert_product(db, payload: dict[str, str | int | bool]) -> Product:
    product = db.query(Product).filter(Product.title == payload["title"]).first()
    if product is None:
        product = Product(**payload)
        db.add(product)
        db.flush()
        return product

    for key, value in payload.items():
        setattr(product, key, value)
    db.flush()
    return product


def _ensure_order(
    db,
    *,
    client_id: int,
    product: Product,
    quantity: int,
    selected_ready_date: date,
    status: str,
    tracking_stage: str,
    loyalty_progress: int,
) -> Order:
    order = (
        db.query(Order)
        .filter(
            Order.client_id == client_id,
            Order.product_id == product.id,
            Order.status == status,
            Order.tracking_stage == tracking_stage,
        )
        .first()
    )
    if order is None:
        existing_codes = [
            item.order_code
            for item in db.query(Order).filter(Order.order_code.is_not(None)).all()
        ]
        order_code = _next_demo_order_code(existing_codes, selected_ready_date)
        order = Order(
            order_code=order_code,
            client_id=client_id,
            franchise_id=1,
            product_id=product.id,
            product_title=product.title,
            quantity=quantity,
            order_type=product.availability_type,
            selected_ready_date=selected_ready_date,
            status=status,
            tracking_stage=tracking_stage,
            loyalty_progress=loyalty_progress,
        )
        db.add(order)
        db.flush()
        return order

    order.franchise_id = 1
    order.product_title = product.title
    order.quantity = quantity
    order.order_type = product.availability_type
    order.selected_ready_date = selected_ready_date
    order.status = status
    order.tracking_stage = tracking_stage
    order.loyalty_progress = loyalty_progress
    db.flush()
    return order


def _next_demo_order_code(existing_codes: list[str], code_date: date) -> str:
    prefix = f"AV-{code_date.strftime('%Y%m%d')}-"
    next_number = 1
    for code in existing_codes:
        if not code.startswith(prefix):
            continue
        suffix = code.split("-")[-1]
        if suffix.isdigit():
            next_number = max(next_number, int(suffix) + 1)
    return f"{prefix}{next_number:04d}"


def _ensure_task(
    db,
    *,
    order_id: int,
    franchise_id: int,
    title: str,
    priority: str,
    operation_stage: str,
    status: str,
    assigned_to: int | None,
    assigned_to_name: str | None,
    created_by: int | None,
    started_at: datetime | None,
    completed_at: datetime | None,
    created_at: datetime,
    updated_at: datetime,
) -> ProductionTask:
    task = (
        db.query(ProductionTask)
        .filter(
            ProductionTask.order_id == order_id,
            ProductionTask.operation_stage == operation_stage,
        )
        .first()
    )
    if task is None:
        task = ProductionTask(
            order_id=order_id,
            franchise_id=franchise_id,
            title=title,
            priority=priority,
            operation_stage=operation_stage,
            status=status,
            assigned_to=assigned_to,
            assigned_to_name=assigned_to_name,
            created_by=created_by,
            started_at=started_at,
            completed_at=completed_at,
            created_at=created_at,
            updated_at=updated_at,
        )
        db.add(task)
        db.flush()
        return task

    task.franchise_id = franchise_id
    task.title = title
    task.priority = priority
    task.status = status
    task.assigned_to = assigned_to
    task.assigned_to_name = assigned_to_name
    task.created_by = created_by
    task.started_at = started_at
    task.completed_at = completed_at
    task.created_at = created_at
    task.updated_at = updated_at
    db.flush()
    return task


def seed() -> None:
    Base.metadata.create_all(bind=engine)
    _ensure_sqlite_schema()
    db = SessionLocal()
    demo_users = [
        {
            "email": "client@avishu.com",
            "full_name": "Клиент AVISHU",
            "role": "client",
            "franchise_id": 1,
            "password": "demo123",
        },
        {
            "email": "franchisee@avishu.com",
            "full_name": "Франчайзи AVISHU",
            "role": "franchisee",
            "franchise_id": 1,
            "password": "demo123",
        },
        {
            "email": "production.manager@avishu.com",
            "full_name": "Менеджер цеха AVISHU",
            "role": "production",
            "production_type": "manager",
            "specialization": None,
            "franchise_id": 1,
            "password": "demo123",
        },
        {
            "email": "1@gmail.com",
            "full_name": "Швея 1",
            "role": "production",
            "production_type": "worker",
            "specialization": "sewing",
            "franchise_id": 1,
            "password": "demo123",
        },
        {
            "email": "2@gmail.com",
            "full_name": "Швея 2",
            "role": "production",
            "production_type": "worker",
            "specialization": "sewing",
            "franchise_id": 1,
            "password": "demo123",
        },
        {
            "email": "3@gmail.com",
            "full_name": "Швея 3",
            "role": "production",
            "production_type": "worker",
            "specialization": "sewing",
            "franchise_id": 1,
            "password": "demo123",
        },
    ]
    try:
        users_by_email = {
            item["email"]: _upsert_user(db, item) for item in demo_users
        }

        product_payloads = [
            {
                "title": "Футболка BRIGHT",
                "description": "Минималистичная базовая футболка из женской линии AVISHU.",
                "price": 15200,
                "currency": "₸",
                "image_url": "https://avishu.kz/wp-content/uploads/2024/09/BRIGHT_madg5.webp",
                "availability_type": "in_stock",
                "default_ready_days": 2,
                "is_active": True,
            },
            {
                "title": "Лонгслив SKIN",
                "description": "Лаконичный лонгслив AVISHU для многослойных образов.",
                "price": 22000,
                "currency": "₸",
                "image_url": "https://avishu.kz/wp-content/uploads/2025/12/SKIN-cofee_1.webp",
                "availability_type": "in_stock",
                "default_ready_days": 2,
                "is_active": True,
            },
            {
                "title": "Юбка ALL.INN",
                "description": "Чистый силуэт с фирменной стилистикой AVISHU.",
                "price": 23500,
                "currency": "₸",
                "image_url": "https://avishu.kz/wp-content/uploads/2025/12/ALL.INN_skirt-bl1.webp",
                "availability_type": "made_to_order",
                "default_ready_days": 5,
                "is_active": True,
            },
            {
                "title": "Футболка ALL.INN",
                "description": "Графичная футболка женской категории каталога AVISHU.",
                "price": 24500,
                "currency": "₸",
                "image_url": "https://avishu.kz/wp-content/uploads/2025/12/ALLINN_wh3.webp",
                "availability_type": "in_stock",
                "default_ready_days": 2,
                "is_active": True,
            },
            {
                "title": "Лонгслив AVI",
                "description": "Спокойная база для повседневного премиального гардероба.",
                "price": 25000,
                "currency": "₸",
                "image_url": "https://avishu.kz/wp-content/uploads/2025/11/avi_wh2.webp",
                "availability_type": "made_to_order",
                "default_ready_days": 4,
                "is_active": True,
            },
            {
                "title": "Рубашка EVO",
                "description": "Структурная рубашка AVISHU с акцентом на форму и посадку.",
                "price": 27200,
                "currency": "₸",
                "image_url": "https://avishu.kz/wp-content/uploads/2025/04/IMG_0335-1.webp",
                "availability_type": "made_to_order",
                "default_ready_days": 5,
                "is_active": True,
            },
            {
                "title": "Джогеры ATTN",
                "description": "Комфортный силуэт с фирменной минималистичной подачей бренда.",
                "price": 27500,
                "currency": "₸",
                "image_url": "https://avishu.kz/wp-content/uploads/2024/11/attn_j_bl1.webp",
                "availability_type": "in_stock",
                "default_ready_days": 2,
                "is_active": True,
            },
            {
                "title": "LOOM худи",
                "description": "Объёмное худи AVISHU из женской коллекции.",
                "price": 32000,
                "currency": "₸",
                "image_url": "https://avishu.kz/wp-content/uploads/2025/11/loom_grey1.webp",
                "availability_type": "made_to_order",
                "default_ready_days": 6,
                "is_active": True,
            },
            {
                "title": "Платье-футболка ALL.INN",
                "description": "Свободная длина и фирменная графика бренда AVISHU.",
                "price": 32000,
                "currency": "₸",
                "image_url": "https://avishu.kz/wp-content/uploads/2025/12/ALL.INN_t-shirt-taup2.webp",
                "availability_type": "made_to_order",
                "default_ready_days": 6,
                "is_active": True,
            },
        ]
        products = [_upsert_product(db, payload) for payload in product_payloads]

        db.commit()
    finally:
        db.close()

    sync_supabase_users(demo_users)
    print("Seed complete.")
    print("Credentials: client@avishu.com / demo123")
    print("Credentials: franchisee@avishu.com / demo123")
    print("Credentials: production.manager@avishu.com / demo123")
    print("Credentials: 1@gmail.com / demo123")
    print("Credentials: 2@gmail.com / demo123")
    print("Credentials: 3@gmail.com / demo123")


if __name__ == "__main__":
    seed()
