from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from database import get_db
from redis_client import CacheBackend, get_cache
from schemas.pydantic_models import ChatRequest, ChatResponse
from services.chat_service import get_chat_response

router = APIRouter(prefix="/chat", tags=["chat"])


@router.post("/message", response_model=ChatResponse)
def chat_message(
    request: ChatRequest,
    db: Session = Depends(get_db),
    cache: CacheBackend = Depends(get_cache),
) -> ChatResponse:
    return get_chat_response(db=db, cache=cache, request=request)