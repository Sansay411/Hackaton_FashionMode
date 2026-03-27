from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth import get_current_user
from app.database import get_db
from app.models import Product
from app.schemas import ProductOut

router = APIRouter(tags=["products"])


@router.get("/products", response_model=list[ProductOut])
def get_products(
    db: Session = Depends(get_db),
    _current_user=Depends(get_current_user),
) -> list[ProductOut]:
    products = db.query(Product).filter(Product.is_active.is_(True)).order_by(Product.id.asc()).all()
    return [ProductOut.model_validate(item) for item in products]

