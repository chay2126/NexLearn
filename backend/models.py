from __future__ import annotations

from sqlalchemy import Enum, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.types import JSON

from database import Base

json_config_type = JSON().with_variant(JSONB, "postgresql")


class Topic(Base):
    __tablename__ = "topics"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    title: Mapped[str] = mapped_column(String(120), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    type: Mapped[str] = mapped_column(
        Enum("chemistry", "english", name="topic_type"),
        nullable=False,
        index=True,
    )
    formula: Mapped[str] = mapped_column(String(255), nullable=False)
    simulation: Mapped["Simulation"] = relationship(
        back_populates="topic",
        uselist=False,
        cascade="all, delete-orphan",
    )


class Simulation(Base):
    __tablename__ = "simulations"
    __table_args__ = (UniqueConstraint("topic_id", name="uq_simulations_topic_id"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    topic_id: Mapped[int] = mapped_column(
        ForeignKey("topics.id", ondelete="CASCADE"),
        nullable=False,
    )
    config: Mapped[dict] = mapped_column(json_config_type, nullable=False)
    topic: Mapped[Topic] = relationship(back_populates="simulation")

