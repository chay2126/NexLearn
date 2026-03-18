from __future__ import annotations

import json
import os
import time
from threading import Lock
from typing import Protocol

try:
    import redis
except ModuleNotFoundError:  # pragma: no cover - dependency install handles this
    redis = None

DEFAULT_TTL_SECONDS = 60


class CacheBackend(Protocol):
    def get_json(self, key: str) -> dict | list | None:
        ...

    def set_json(
        self,
        key: str,
        value: dict | list,
        ttl_seconds: int = DEFAULT_TTL_SECONDS,
    ) -> None:
        ...


class RedisCache:
    def __init__(self, url: str) -> None:
        if redis is None:
            raise RuntimeError("redis dependency is not installed.")
        self._client = redis.Redis.from_url(url, decode_responses=True)
        self._client.ping()

    def get_json(self, key: str) -> dict | list | None:
        payload = self._client.get(key)
        if payload is None:
            return None
        return json.loads(payload)

    def set_json(
        self,
        key: str,
        value: dict | list,
        ttl_seconds: int = DEFAULT_TTL_SECONDS,
    ) -> None:
        self._client.setex(key, ttl_seconds, json.dumps(value))


class InMemoryCache:
    def __init__(self) -> None:
        self._entries: dict[str, tuple[float, dict | list]] = {}
        self._lock = Lock()

    def get_json(self, key: str) -> dict | list | None:
        with self._lock:
            entry = self._entries.get(key)
            if entry is None:
                return None

            expires_at, payload = entry
            if expires_at <= time.time():
                del self._entries[key]
                return None

            return payload

    def set_json(
        self,
        key: str,
        value: dict | list,
        ttl_seconds: int = DEFAULT_TTL_SECONDS,
    ) -> None:
        with self._lock:
            self._entries[key] = (time.time() + ttl_seconds, value)


_cache_instance: CacheBackend | None = None


def get_cache() -> CacheBackend:
    global _cache_instance

    if _cache_instance is not None:
        return _cache_instance

    redis_url = os.getenv("REDIS_URL")
    if redis_url:
        try:
            _cache_instance = RedisCache(redis_url)
            return _cache_instance
        except Exception:
            pass

    _cache_instance = InMemoryCache()
    return _cache_instance

