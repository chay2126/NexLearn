from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from database import get_db
from redis_client import CacheBackend, get_cache
from schemas.pydantic_models import EnglishRequest, EnglishResponse
from services.english_service import get_english_analysis_response

router = APIRouter(prefix="/english", tags=["english"])


@router.post("/analyze", response_model=EnglishResponse)
def analyze_sentence(
    request: EnglishRequest,
    db: Session = Depends(get_db),
    cache: CacheBackend = Depends(get_cache),
) -> EnglishResponse:
    return get_english_analysis_response(db=db, cache=cache, request=request)

