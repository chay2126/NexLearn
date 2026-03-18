from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from database import get_db
from models import Topic
from schemas.pydantic_models import SimulationConfig, SimulationResponse, TopicSummary

router = APIRouter(tags=["topics"])


@router.get("/topics", response_model=list[TopicSummary])
def get_topics(db: Session = Depends(get_db)) -> list[TopicSummary]:
    topics = db.scalars(
        select(Topic)
        .options(selectinload(Topic.simulation))
        .order_by(Topic.type.asc(), Topic.id.asc())
    ).all()
    return [TopicSummary.model_validate(topic) for topic in topics]


@router.get("/simulation/{topic_id}", response_model=SimulationResponse)
def get_simulation(topic_id: int, db: Session = Depends(get_db)) -> SimulationResponse:
    topic = db.scalar(
        select(Topic)
        .options(selectinload(Topic.simulation))
        .where(Topic.id == topic_id)
    )
    if topic is None or topic.simulation is None:
        raise HTTPException(status_code=404, detail="Simulation not found.")

    return SimulationResponse(
        topic=TopicSummary.model_validate(topic),
        config=SimulationConfig.model_validate(topic.simulation.config),
    )

