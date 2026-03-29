from __future__ import annotations

import httpx
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.models import User

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


def _is_supabase_configured() -> bool:
    return bool(settings.supabase_url and settings.supabase_anon_key)


def _ensure_supabase_configured() -> None:
    if not _is_supabase_configured():
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Supabase auth is not configured",
        )


def _supabase_sign_in(email: str, password: str) -> tuple[str, str]:
    _ensure_supabase_configured()
    url = f"{settings.supabase_url.rstrip('/')}/auth/v1/token?grant_type=password"
    headers = {
        "apikey": settings.supabase_anon_key,
        "Content-Type": "application/json",
    }
    try:
        response = httpx.post(
            url,
            headers=headers,
            json={"email": email, "password": password},
            timeout=settings.supabase_timeout_seconds,
        )
    except httpx.HTTPError:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Supabase auth service unavailable",
        )

    if response.status_code >= 400:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    data = response.json()
    access_token = data.get("access_token")
    auth_user = data.get("user") or {}
    auth_email = auth_user.get("email")
    if not access_token or not auth_email:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Supabase authentication response",
        )
    return access_token, auth_email


def authenticate_with_supabase(db: Session, email: str, password: str) -> tuple[str, User]:
    if not _is_supabase_configured():
        normalized_email = email.strip().lower()
        user = db.query(User).filter(User.email == normalized_email).first()
        if not user or user.password != password:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password",
            )
        return f"local-token:{user.id}", user

    access_token, auth_email = _supabase_sign_in(email=email, password=password)
    user = db.query(User).filter(User.email == auth_email).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Authenticated user is not registered in backend roles",
        )
    return access_token, user


def _create_supabase_user(email: str, password: str) -> None:
    if not settings.supabase_url or not settings.supabase_service_role_key:
        return

    url = f"{settings.supabase_url.rstrip('/')}/auth/v1/admin/users"
    headers = {
        "apikey": settings.supabase_service_role_key,
        "Authorization": f"Bearer {settings.supabase_service_role_key}",
        "Content-Type": "application/json",
    }
    try:
        response = httpx.post(
            url,
            headers=headers,
            json={
                "email": email,
                "password": password,
                "email_confirm": True,
            },
            timeout=settings.supabase_timeout_seconds,
        )
    except httpx.HTTPError:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Supabase auth service unavailable",
        )

    if response.status_code in {200, 201}:
        return

    body_text = response.text.lower()
    if "already" in body_text or "exists" in body_text:
        return

    raise HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail="Unable to register user in Supabase auth",
    )


def create_auth_user(email: str, password: str) -> None:
    _create_supabase_user(email=email, password=password)


def register_client(
    db: Session,
    *,
    email: str,
    password: str,
    full_name: str,
    franchise_id: int = 1,
) -> tuple[str, User]:
    normalized_email = email.strip().lower()
    normalized_name = full_name.strip()
    if not normalized_name:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Full name is required",
        )

    existing_user = db.query(User).filter(User.email == normalized_email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="User with this email already exists",
        )

    create_auth_user(email=normalized_email, password=password)

    user = User(
        email=normalized_email,
        full_name=normalized_name,
        role="client",
        franchise_id=franchise_id,
        password=password,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    if not _is_supabase_configured():
        return f"local-token:{user.id}", user

    access_token, _ = _supabase_sign_in(email=normalized_email, password=password)
    return access_token, user


def _supabase_get_user_email(access_token: str) -> str:
    _ensure_supabase_configured()
    url = f"{settings.supabase_url.rstrip('/')}/auth/v1/user"
    headers = {
        "apikey": settings.supabase_anon_key,
        "Authorization": f"Bearer {access_token}",
    }
    try:
        response = httpx.get(url, headers=headers, timeout=settings.supabase_timeout_seconds)
    except httpx.HTTPError:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Supabase auth service unavailable",
        )

    if response.status_code >= 400:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
        )

    data = response.json()
    email = data.get("email")
    if not email:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
        )
    return email


def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid authentication credentials",
    )

    if token.startswith("local-token:"):
        try:
            user_id = int(token.split(":", maxsplit=1)[1])
        except (IndexError, ValueError):
            raise credentials_exception
        user = db.query(User).filter(User.id == user_id).first()
    else:
        email = _supabase_get_user_email(access_token=token)
        user = db.query(User).filter(User.email == email).first()
    if not user:
        raise credentials_exception
    return user


def require_role(*allowed_roles: str):
    def dependency(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in allowed_roles:
            raise HTTPException(status_code=403, detail="Access denied for role")
        return current_user

    return dependency


def require_production_type(*allowed_types: str):
    def dependency(current_user: User = Depends(require_role("production"))) -> User:
        if current_user.production_type not in allowed_types:
            raise HTTPException(status_code=403, detail="Access denied for production type")
        return current_user

    return dependency
