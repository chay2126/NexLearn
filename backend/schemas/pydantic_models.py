from __future__ import annotations

from enum import Enum

from pydantic import BaseModel, ConfigDict, Field


class TopicType(str, Enum):
    chemistry = "chemistry"
    english = "english"


class InputDefinition(BaseModel):
    name: str
    min: float
    max: float
    default: float


class SimulationConfig(BaseModel):
    inputs: list[InputDefinition] = Field(default_factory=list)
    input_type: str | None = None
    visualization: str


class TopicSummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    description: str
    type: TopicType
    formula: str


class SimulationResponse(BaseModel):
    topic: TopicSummary
    config: SimulationConfig


class ChemistryRequest(BaseModel):
    topic_id: int = Field(default=1, ge=1)
    concentration: float = Field(gt=0)
    temperature: float = Field(gt=0)


class GraphPoint(BaseModel):
    time: float
    concentration: float


class ChemistryResponse(BaseModel):
    topic_id: int
    rate: float
    rate_constant: float
    graph_points: list[GraphPoint]
    formula: str
    cache_hit: bool


class EnglishRequest(BaseModel):
    topic_id: int = Field(default=2, ge=1)
    sentence: str = Field(min_length=1, max_length=300)


class TextSegment(BaseModel):
    text: str
    role: str


class EnglishResponse(BaseModel):
    topic_id: int
    sentence: str
    subject: str
    verb: str
    object: str
    segments: list[TextSegment]
    visualization: str
    cache_hit: bool

class ChatMessage(BaseModel):
    role: str        # "user" or "model"
    content: str

class ChatRequest(BaseModel):
    topic_id: int = Field(ge=1)
    message: str = Field(min_length=1, max_length=1000)
    history: list[ChatMessage] = Field(default_factory=list)

class ChatResponse(BaseModel):
    reply: str
    cache_hit: bool