from __future__ import annotations

import os
from pathlib import Path

import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient

os.environ["DATABASE_URL"] = "sqlite:///./test_suite.db"
os.environ["SUPABASE_URL"] = "https://test-project.supabase.co"
os.environ["SUPABASE_ANON_KEY"] = "test-anon-key"
os.environ["SUPABASE_SERVICE_ROLE_KEY"] = "test-service-role-key"

from app.database import Base, SessionLocal, engine
from app.main import app
from app.models import Product, User
import app.auth as auth_module


def _seed_demo_data() -> None:
    db = SessionLocal()
    try:
        db.add_all(
            [
                User(
                    email="client@avishu.com",
                    full_name="Demo Client",
                    role="client",
                    franchise_id=1,
                    password="demo123",
                ),
                User(
                    email="franchisee@avishu.com",
                    full_name="Demo Franchisee",
                    role="franchisee",
                    franchise_id=1,
                    password="demo123",
                ),
                User(
                    email="production@avishu.com",
                    full_name="Demo Production",
                    role="production",
                    franchise_id=1,
                    password="demo123",
                ),
            ]
        )
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


@pytest.fixture(autouse=True)
def reset_database():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    _seed_demo_data()
    yield
    Base.metadata.drop_all(bind=engine)


@pytest.fixture(autouse=True)
def fake_supabase(monkeypatch: pytest.MonkeyPatch):
    token_by_email = {
        "client@avishu.com": "token_client",
        "franchisee@avishu.com": "token_franchisee",
        "production@avishu.com": "token_production",
    }
    email_by_token = {token: email for email, token in token_by_email.items()}

    def _fake_sign_in(email: str, password: str) -> tuple[str, str]:
        if password != "demo123" or email not in token_by_email:
            raise HTTPException(status_code=401, detail="Invalid email or password")
        return token_by_email[email], email

    def _fake_get_user_email(access_token: str) -> str:
        email = email_by_token.get(access_token)
        if not email:
            raise HTTPException(status_code=401, detail="Invalid authentication credentials")
        return email

    monkeypatch.setattr(auth_module, "_supabase_sign_in", _fake_sign_in)
    monkeypatch.setattr(auth_module, "_supabase_get_user_email", _fake_get_user_email)


@pytest.fixture(scope="session", autouse=True)
def cleanup_test_db_file():
    yield
    engine.dispose()
    db_path = Path("test_suite.db")
    if db_path.exists():
        try:
            db_path.unlink()
        except PermissionError:
            pass


@pytest.fixture
def api_client():
    with TestClient(app) as client:
        yield client
