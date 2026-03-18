from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from database import get_db
from redis_client import CacheBackend, get_cache
from schemas.pydantic_models import ChemistryRequest, ChemistryResponse
from services.chemistry_service import get_reaction_rate_response

router = APIRouter(prefix="/chemistry", tags=["chemistry"])


@router.post("/reaction-rate", response_model=ChemistryResponse)
def reaction_rate(
    request: ChemistryRequest,
    db: Session = Depends(get_db),
    cache: CacheBackend = Depends(get_cache),
) -> ChemistryResponse:
    return get_reaction_rate_response(db=db, cache=cache, request=request)

