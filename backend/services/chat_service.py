from __future__ import annotations

import os
import google.generativeai as genai
from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from models import Topic
from redis_client import CacheBackend, DEFAULT_TTL_SECONDS
from schemas.pydantic_models import ChatRequest, ChatResponse, ChatMessage

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

SYSTEM_PROMPT = """You are NexLearn, a friendly and focused academic tutor.
You are currently helping a student learn about: {topic_title}.

Topic description: {topic_description}
Formula: {topic_formula}

Rules you must follow:
- Only answer questions related to this topic.
- If the student asks something unrelated, politely redirect them back to the topic.
- Keep answers short, clear and student-friendly.
- Use simple examples where helpful.
- Never answer in more than 5 sentences unless the student asks for detail.
"""


def get_chat_response(
    db: Session,
    cache: CacheBackend,
    request: ChatRequest,
) -> ChatResponse:
    # Check cache — only cache single-turn questions (no history)
    cache_key = None
    if not request.history:
        cache_key = build_chat_cache_key(request)
        cached = cache.get_json(cache_key)
        if isinstance(cached, dict):
            cached["cache_hit"] = True
            return ChatResponse.model_validate(cached)

    # Fetch topic for context
    topic = db.scalar(
        select(Topic)
        .options(selectinload(Topic.simulation))
        .where(Topic.id == request.topic_id)
    )
    if topic is None:
        raise HTTPException(status_code=404, detail="Topic not found.")

    if not GEMINI_API_KEY:
        raise HTTPException(status_code=500, detail="Gemini API key not configured.")

    reply = call_gemini(
        topic=topic,
        message=request.message,
        history=request.history,
    )

    response = ChatResponse(reply=reply, cache_hit=False)

    # Only cache if no history (first question)
    if cache_key:
        cache.set_json(
            cache_key,
            response.model_dump(),
            ttl_seconds=DEFAULT_TTL_SECONDS,
        )

    return response


def call_gemini(topic, message: str, history: list[ChatMessage]) -> str:
    genai.configure(api_key=GEMINI_API_KEY)
    model = genai.GenerativeModel(
        model_name="gemini-2.5-flash-lite",
        system_instruction=SYSTEM_PROMPT.format(
            topic_title=topic.title,
            topic_description=topic.description,
            topic_formula=topic.formula,
        ),
    )

    # Convert history to Gemini format
    gemini_history = [
        {"role": msg.role, "parts": [msg.content]}
        for msg in history
    ]

    chat = model.start_chat(history=gemini_history)

    try:
        response = chat.send_message(message)
        return response.text
    except Exception as e:
        raise HTTPException(
            status_code=502,
            detail=f"Gemini API error: {str(e)}",
        )


def build_chat_cache_key(request: ChatRequest) -> str:
    return (
        f"chat:"
        f"topic={request.topic_id}:"
        f"msg={request.message.lower().strip()}"
    )