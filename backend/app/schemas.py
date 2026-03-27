from __future__ import annotations

from datetime import date, datetime

from pydantic import BaseModel


class UserOut(BaseModel):
    id: int
    email: str
    full_name: str
    role: str
    franchise_id: int | None
    created_at: datetime

    model_config = {"from_attributes": True}


class LoginRequest(BaseModel):
    email: str
    password: str


class LoginResponse(BaseModel):
    token: str
    user: UserOut


class ProductOut(BaseModel):
    id: int
    title: str
    description: str
    price: float
    currency: str
    image_url: str
    availability_type: str
    default_ready_days: int
    is_active: bool

    model_config = {"from_attributes": True}


class OrderCreate(BaseModel):
    client_id: int
    franchise_id: int
    product_id: int
    quantity: int
    order_type: str
    selected_ready_date: date | None = None


class OrderStatusUpdate(BaseModel):
    status: str


class OrderOut(BaseModel):
    id: int
    client_id: int
    franchise_id: int
    product_id: int
    product_title: str
    quantity: int
    order_type: str
    selected_ready_date: date
    status: str
    tracking_stage: str
    loyalty_progress: int
    created_at: datetime

    model_config = {"from_attributes": True}


class ProductionTaskOut(BaseModel):
    id: int
    order_id: int
    franchise_id: int
    title: str
    status: str
    operation_stage: str
    created_at: datetime

    model_config = {"from_attributes": True}

