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
from app.models import Order, Product, User
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
                    email="production.manager@avishu.com",
                    full_name="Demo Production Manager",
                    role="production",
                    production_type="manager",
                    specialization=None,
                    franchise_id=1,
                    password="demo123",
                ),
                User(
                    email="1@gmail.com",
                    full_name="Швея 1",
                    role="production",
                    production_type="worker",
                    specialization="sewing",
                    franchise_id=1,
                    password="demo123",
                ),
                User(
                    email="2@gmail.com",
                    full_name="Швея 2",
                    role="production",
                    production_type="worker",
                    specialization="sewing",
                    franchise_id=1,
                    password="demo123",
                ),
                User(
                    email="3@gmail.com",
                    full_name="Швея 3",
                    role="production",
                    production_type="worker",
                    specialization="sewing",
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
        for index, order in enumerate(db.query(Order).order_by(Order.id.asc()).all(), start=1):
            order.order_code = f"AV-20260329-{index:04d}"
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
    def _fake_sign_in(email: str, password: str) -> tuple[str, str]:
        db = SessionLocal()
        try:
            user = db.query(User).filter(User.email == email.strip().lower()).first()
        finally:
            db.close()

        if not user or user.password != password:
            raise HTTPException(status_code=401, detail="Invalid email or password")
        return f"token_{user.id}", user.email

    def _fake_get_user_email(access_token: str) -> str:
        if not access_token.startswith("token_"):
            raise HTTPException(status_code=401, detail="Invalid authentication credentials")
        raw_id = access_token.removeprefix("token_")
        if not raw_id.isdigit():
            raise HTTPException(status_code=401, detail="Invalid authentication credentials")

        db = SessionLocal()
        try:
            user = db.query(User).filter(User.id == int(raw_id)).first()
        finally:
            db.close()

        if not user:
            raise HTTPException(status_code=401, detail="Invalid authentication credentials")
        return user.email

    def _fake_create_user(email: str, password: str) -> None:
        return None

    monkeypatch.setattr(auth_module, "_supabase_sign_in", _fake_sign_in)
    monkeypatch.setattr(auth_module, "_supabase_get_user_email", _fake_get_user_email)
    monkeypatch.setattr(auth_module, "_create_supabase_user", _fake_create_user)


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
