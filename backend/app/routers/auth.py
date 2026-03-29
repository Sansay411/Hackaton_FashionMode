from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth import authenticate_with_supabase, register_client
from app.database import get_db
from app.schemas import LoginRequest, LoginResponse, RegisterRequest, UserOut

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login", response_model=LoginResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)) -> LoginResponse:
    token, user = authenticate_with_supabase(db=db, email=payload.email, password=payload.password)
    return LoginResponse(token=token, user=UserOut.model_validate(user))


@router.post("/register", response_model=LoginResponse)
def register(payload: RegisterRequest, db: Session = Depends(get_db)) -> LoginResponse:
    token, user = register_client(
        db=db,
        email=payload.email,
        password=payload.password,
        full_name=payload.full_name,
    )
    return LoginResponse(token=token, user=UserOut.model_validate(user))
