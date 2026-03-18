from __future__ import annotations

import os
from collections.abc import Generator

from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session, declarative_base, sessionmaker

Base = declarative_base()

APP_MODE = os.getenv("APP_MODE", "development").lower()
DATABASE_URL = os.getenv("DATABASE_URL") or (
    "postgresql+psycopg://nexlearn:nexlearn@localhost:5432/nexlearn"
    if APP_MODE == "production"
    else "sqlite:///./nexlearn.db"
)

_connect_args: dict[str, object] = {}
if DATABASE_URL.startswith("sqlite"):
    _connect_args["check_same_thread"] = False

engine = create_engine(
    DATABASE_URL,
    echo=False,
    future=True,
    connect_args=_connect_args,
)
SessionLocal = sessionmaker(
    bind=engine,
    autocommit=False,
    autoflush=False,
    expire_on_commit=False,
)


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db() -> None:
    import models

    Base.metadata.create_all(bind=engine)
    with SessionLocal() as db:
        seed_reference_data(db, models)


def seed_reference_data(db: Session, models_module) -> None:
    existing_topic = db.scalar(select(models_module.Topic.id).limit(1))
    if existing_topic is not None:
        return

    chemistry_topic = models_module.Topic(
        title="Reaction Rate Dynamics",
        description=(
            "Explore how concentration and temperature influence the speed of a "
            "first-order reaction and the resulting concentration decay curve."
        ),
        type="chemistry",
        formula="C(t) = C0 * e^(-kt)",
    )
    english_topic = models_module.Topic(
        title="Sentence Structure Explorer",
        description=(
            "Type an English sentence to identify its subject, verb, and object "
            "with immediate visual highlighting."
        ),
        type="english",
        formula="Subject + Verb + Object",
    )

    db.add_all([chemistry_topic, english_topic])
    db.flush()

    db.add_all(
        [
            models_module.Simulation(
                topic_id=chemistry_topic.id,
                config={
                    "inputs": [
                        {
                            "name": "concentration",
                            "min": 0.0,
                            "max": 10.0,
                            "default": 1.0,
                        },
                        {
                            "name": "temperature",
                            "min": 250.0,
                            "max": 500.0,
                            "default": 300.0,
                        },
                    ],
                    "visualization": "line_chart",
                },
            ),
            models_module.Simulation(
                topic_id=english_topic.id,
                config={
                    "input_type": "text",
                    "visualization": "highlight",
                },
            ),
        ]
    )
    db.commit()
