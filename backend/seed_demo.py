from __future__ import annotations

import httpx

from app.config import settings
from app.database import Base, SessionLocal, engine
from app.models import Product, User


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


def seed() -> None:
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    demo_users = [
        {
            "email": "client@avishu.com",
            "full_name": "Demo Client",
            "role": "client",
            "franchise_id": 1,
            "password": "demo123",
        },
        {
            "email": "franchisee@avishu.com",
            "full_name": "Demo Franchisee",
            "role": "franchisee",
            "franchise_id": 1,
            "password": "demo123",
        },
        {
            "email": "production@avishu.com",
            "full_name": "Demo Production",
            "role": "production",
            "franchise_id": 1,
            "password": "demo123",
        },
    ]
    try:
        if db.query(User).count() == 0:
            db.add_all(
                [
                    User(**demo_users[0]),
                    User(**demo_users[1]),
                    User(**demo_users[2]),
                ]
            )

        if db.query(Product).count() == 0:
            db.add_all(
                [
                    Product(
                        title="Classic Black Blazer",
                        description="Premium tailored blazer.",
                        price=199.00,
                        currency="USD",
                        image_url="https://example.com/blazer.jpg",
                        availability_type="made_to_order",
                        default_ready_days=5,
                        is_active=True,
                    ),
                    Product(
                        title="White Capsule Shirt",
                        description="Minimal premium white shirt.",
                        price=89.00,
                        currency="USD",
                        image_url="https://example.com/shirt.jpg",
                        availability_type="ready_stock",
                        default_ready_days=2,
                        is_active=True,
                    ),
                ]
            )

        db.commit()
    finally:
        db.close()

    sync_supabase_users(demo_users)
    print("Seed complete.")
    print("Credentials: client@avishu.com / demo123")
    print("Credentials: franchisee@avishu.com / demo123")
    print("Credentials: production@avishu.com / demo123")


if __name__ == "__main__":
    seed()
