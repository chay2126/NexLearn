from __future__ import annotations

import re

from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from models import Topic
from redis_client import CacheBackend, DEFAULT_TTL_SECONDS
from schemas.pydantic_models import EnglishRequest, EnglishResponse, TextSegment

TOKEN_PATTERN = re.compile(r"\w+(?:'\w+)?|[^\w\s]")
PUNCTUATION = {".", ",", "!", "?", ";", ":"}
PREPOSITIONS = {
    "about",
    "above",
    "across",
    "after",
    "against",
    "along",
    "around",
    "at",
    "before",
    "behind",
    "below",
    "beneath",
    "beside",
    "between",
    "by",
    "during",
    "for",
    "from",
    "in",
    "inside",
    "into",
    "near",
    "of",
    "on",
    "over",
    "through",
    "to",
    "toward",
    "under",
    "with",
}
AUXILIARY_VERBS = {
    "am",
    "are",
    "be",
    "been",
    "being",
    "can",
    "could",
    "did",
    "do",
    "does",
    "had",
    "has",
    "have",
    "is",
    "may",
    "might",
    "must",
    "shall",
    "should",
    "was",
    "were",
    "will",
    "would",
}
COMMON_VERBS = {
    "accept",
    "analyze",
    "arrive",
    "ask",
    "build",
    "calculate",
    "call",
    "change",
    "check",
    "chase",
    "clarify",
    "collect",
    "compare",
    "create",
    "describe",
    "discover",
    "discuss",
    "draw",
    "drive",
    "eat",
    "explain",
    "explore",
    "find",
    "highlight",
    "improve",
    "increase",
    "investigate",
    "jump",
    "know",
    "learn",
    "like",
    "love",
    "make",
    "mix",
    "move",
    "need",
    "observe",
    "paint",
    "predict",
    "present",
    "produce",
    "read",
    "run",
    "see",
    "show",
    "solve",
    "speak",
    "study",
    "summarize",
    "teach",
    "test",
    "trace",
    "understand",
    "visualize",
    "watch",
    "write",
}


def get_english_analysis_response(
    db: Session,
    cache: CacheBackend,
    request: EnglishRequest,
) -> EnglishResponse:
    sentence = normalize_sentence(request.sentence)
    cache_key = build_english_cache_key(sentence)
    cached = cache.get_json(cache_key)
    if isinstance(cached, dict):
        cached["cache_hit"] = True
        return EnglishResponse.model_validate(cached)

    topic = db.scalar(
        select(Topic)
        .options(selectinload(Topic.simulation))
        .where(Topic.id == request.topic_id, Topic.type == "english")
    )
    if topic is None or topic.simulation is None:
        raise HTTPException(status_code=404, detail="English topic not found.")

    validate_english_inputs(topic.simulation.config)
    analysis = analyze_sentence(sentence)

    response = EnglishResponse(
        topic_id=topic.id,
        sentence=sentence,
        subject=analysis["subject"],
        verb=analysis["verb"],
        object=analysis["object"],
        segments=[TextSegment.model_validate(item) for item in analysis["segments"]],
        visualization=topic.simulation.config.get("visualization", "highlight"),
        cache_hit=False,
    )
    cache.set_json(
        cache_key,
        response.model_dump(),
        ttl_seconds=DEFAULT_TTL_SECONDS,
    )
    return response


def build_english_cache_key(sentence: str) -> str:
    return f"english:{sentence.lower()}"


def normalize_sentence(sentence: str) -> str:
    normalized = " ".join(sentence.strip().split())
    if not normalized:
        raise HTTPException(status_code=422, detail="Sentence cannot be empty.")
    return normalized


def validate_english_inputs(config: dict) -> None:
    if config.get("input_type") != "text":
        raise HTTPException(
            status_code=500,
            detail="Simulation configuration is not set up for text analysis.",
        )


def analyze_sentence(sentence: str) -> dict[str, object]:
    tokens = [
        {
            "text": match.group(0),
            "start": match.start(),
            "end": match.end(),
        }
        for match in TOKEN_PATTERN.finditer(sentence)
    ]
    if not tokens:
        raise HTTPException(status_code=422, detail="Sentence cannot be empty.")

    lower_tokens = [token["text"].lower() for token in tokens]
    verb_start, verb_end = locate_verb_phrase(lower_tokens)

    subject_indices = [
        index for index in range(0, verb_start) if lower_tokens[index] not in PUNCTUATION
    ]
    object_indices = locate_object_phrase(lower_tokens, verb_end)

    subject = extract_phrase(sentence, tokens, subject_indices)
    verb = extract_phrase(sentence, tokens, list(range(verb_start, verb_end + 1)))
    obj = extract_phrase(sentence, tokens, object_indices)

    if not subject and verb_start == 0:
        subject = "(implicit you)"

    segments = build_segments(
        sentence=sentence,
        tokens=tokens,
        subject_indices=set(subject_indices),
        verb_indices=set(range(verb_start, verb_end + 1)),
        object_indices=set(object_indices),
    )

    return {
        "subject": subject or "Not detected",
        "verb": verb or "Not detected",
        "object": obj or "Not detected",
        "segments": segments,
    }


def locate_verb_phrase(lower_tokens: list[str]) -> tuple[int, int]:
    for index, token in enumerate(lower_tokens):
        if token in PUNCTUATION:
            continue

        if token in AUXILIARY_VERBS:
            end_index = index
            while (
                end_index + 1 < len(lower_tokens)
                and lower_tokens[end_index + 1] in AUXILIARY_VERBS
            ):
                end_index += 1

            if end_index + 1 < len(lower_tokens) and is_main_verb_candidate(
                lower_tokens[end_index + 1],
                end_index + 1,
                lower_tokens,
            ):
                return index, end_index + 1

            return index, end_index

        if is_main_verb_candidate(token, index, lower_tokens):
            return index, index

    raise HTTPException(
        status_code=422,
        detail="Could not identify a verb in the supplied sentence.",
    )


def is_main_verb_candidate(token: str, index: int, lower_tokens: list[str]) -> bool:
    if token in COMMON_VERBS:
        return True

    if index > 0 and lower_tokens[index - 1] in AUXILIARY_VERBS:
        return True

    if token.endswith("ing") or token.endswith("ed"):
        return True

    if index > 0 and token.endswith("es"):
        return True

    if index > 0 and token.endswith("s") and token not in {"this", "thus", "glass"}:
        return True

    return False


def locate_object_phrase(lower_tokens: list[str], verb_end: int) -> list[int]:
    object_indices: list[int] = []
    for index in range(verb_end + 1, len(lower_tokens)):
        token = lower_tokens[index]
        if token in PUNCTUATION:
            break
        if object_indices and token in PREPOSITIONS:
            break
        object_indices.append(index)
    return object_indices


def extract_phrase(sentence: str, tokens: list[dict], indices: list[int]) -> str:
    if not indices:
        return ""
    start = tokens[indices[0]]["start"]
    end = tokens[indices[-1]]["end"]
    return sentence[start:end].strip()


def build_segments(
    sentence: str,
    tokens: list[dict],
    subject_indices: set[int],
    verb_indices: set[int],
    object_indices: set[int],
) -> list[dict[str, str]]:
    segments: list[dict[str, str]] = []
    cursor = 0

    for index, token in enumerate(tokens):
        if cursor < token["start"]:
            segments.append(
                {
                    "text": sentence[cursor:token["start"]],
                    "role": "plain",
                }
            )

        role = "plain"
        if index in subject_indices:
            role = "subject"
        elif index in verb_indices:
            role = "verb"
        elif index in object_indices:
            role = "object"

        segments.append({"text": token["text"], "role": role})
        cursor = token["end"]

    if cursor < len(sentence):
        segments.append({"text": sentence[cursor:], "role": "plain"})

    return merge_adjacent_segments(segments)


def merge_adjacent_segments(segments: list[dict[str, str]]) -> list[dict[str, str]]:
    merged: list[dict[str, str]] = []
    for segment in segments:
        if not segment["text"]:
            continue

        if merged and merged[-1]["role"] == segment["role"]:
            merged[-1]["text"] += segment["text"]
        else:
            merged.append(segment.copy())
    return merged
