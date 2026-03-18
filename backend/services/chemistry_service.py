from __future__ import annotations

from math import exp

from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from models import Topic
from redis_client import CacheBackend, DEFAULT_TTL_SECONDS
from schemas.pydantic_models import ChemistryRequest, ChemistryResponse, GraphPoint

GAS_CONSTANT = 8.314
ACTIVATION_ENERGY = 8_000.0
PRE_EXPONENTIAL_FACTOR = 0.9


def get_reaction_rate_response(
    db: Session,
    cache: CacheBackend,
    request: ChemistryRequest,
) -> ChemistryResponse:
    cache_key = build_chemistry_cache_key(request)
    cached = cache.get_json(cache_key)
    if isinstance(cached, dict):
        cached["cache_hit"] = True
        return ChemistryResponse.model_validate(cached)

    topic = db.scalar(
        select(Topic)
        .options(selectinload(Topic.simulation))
        .where(Topic.id == request.topic_id, Topic.type == "chemistry")
    )
    if topic is None or topic.simulation is None:
        raise HTTPException(status_code=404, detail="Chemistry topic not found.")

    validate_chemistry_inputs(topic.simulation.config, request)
    rate_constant = calculate_rate_constant(
        concentration=request.concentration,
        temperature=request.temperature,
    )
    rate = round(rate_constant * request.concentration, 6)
    graph_points = build_graph_points(
        initial_concentration=request.concentration,
        rate_constant=rate_constant,
    )

    response = ChemistryResponse(
        topic_id=topic.id,
        rate=rate,
        rate_constant=rate_constant,
        graph_points=graph_points,
        formula=topic.formula,
        cache_hit=False,
    )
    cache.set_json(
        cache_key,
        response.model_dump(),
        ttl_seconds=DEFAULT_TTL_SECONDS,
    )
    return response


def build_chemistry_cache_key(request: ChemistryRequest) -> str:
    return (
        "chemistry:"
        f"topic={request.topic_id}:"
        f"concentration={request.concentration:.2f}:"
        f"temperature={request.temperature:.2f}"
    )


def validate_chemistry_inputs(config: dict, request: ChemistryRequest) -> None:
    input_map = {
        item["name"]: item
        for item in config.get("inputs", [])
        if isinstance(item, dict) and "name" in item
    }

    for field_name in ("concentration", "temperature"):
        bounds = input_map.get(field_name)
        if bounds is None:
            raise HTTPException(
                status_code=500,
                detail=f"Simulation configuration is missing bounds for {field_name}.",
            )

        value = getattr(request, field_name)
        minimum = float(bounds.get("min", value))
        maximum = float(bounds.get("max", value))
        if not minimum <= value <= maximum:
            raise HTTPException(
                status_code=422,
                detail=(
                    f"{field_name} must be between {minimum} and {maximum} "
                    f"for this simulation."
                ),
            )


def calculate_rate_constant(concentration: float, temperature: float) -> float:
    arrhenius_term = exp(-ACTIVATION_ENERGY / (GAS_CONSTANT * temperature))
    concentration_factor = 1.0 + (concentration / 12.0)
    return round(PRE_EXPONENTIAL_FACTOR * arrhenius_term * concentration_factor, 6)


def build_graph_points(
    initial_concentration: float,
    rate_constant: float,
    steps: int = 24,
    step_size: float = 0.5,
) -> list[GraphPoint]:
    points: list[GraphPoint] = []
    for index in range(steps + 1):
        time_value = round(index * step_size, 2)
        concentration = initial_concentration * exp(-rate_constant * time_value)
        points.append(
            GraphPoint(
                time=time_value,
                concentration=round(concentration, 4),
            )
        )
    return points

