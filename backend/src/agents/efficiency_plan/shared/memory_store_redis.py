"""
Redis-backed (with in-memory fallback) memory store.
Converted from shared/memoryStore.redis.js — identical logic.
"""

import json
from typing import Any

from .memory_keys import assert_memory_identity, build_memory_keys

ACTIVE_TTL_SECONDS = 60 * 60 * 24 * 30  # 30 days

# In-memory fallback store (mirrors the JS Map)
_in_memory_store: dict[str, list[str]] = {}

# Optional Redis client — try importing the cache service
_redis_client = None
try:
    from ....services.cache_service import cache_service  # type: ignore

    if hasattr(cache_service, "client") and cache_service.client is not None:
        _redis_client = cache_service.client
except Exception:
    _redis_client = None


def _get_list(key: str) -> list[str]:
    return _in_memory_store.get(key, [])


def _set_list(key: str, value: list[str]) -> None:
    _in_memory_store[key] = value


async def append_event(identity: dict, event: dict) -> dict:
    """Append a validated memory event to the store."""
    validated = assert_memory_identity(identity)
    keys = build_memory_keys(validated)
    events_key = keys["eventsKey"]
    serialized = json.dumps(event, default=str)

    if _redis_client is not None:
        await _redis_client.rpush(events_key, serialized)
        await _redis_client.expire(events_key, ACTIVE_TTL_SECONDS)
    else:
        curr = _get_list(events_key)
        curr.append(serialized)
        _set_list(events_key, curr)

    return event


async def list_recent_events(identity: dict, limit: int = 12) -> list[dict]:
    """Return the most recent `limit` events."""
    validated = assert_memory_identity(identity)
    keys = build_memory_keys(validated)
    events_key = keys["eventsKey"]

    start = max(-limit, -1000)

    if _redis_client is not None:
        rows = await _redis_client.lrange(events_key, start, -1)
    else:
        rows = _get_list(events_key)[start:]

    return [json.loads(item) for item in rows]


async def list_historical_events(
    identity: dict, query: str = "", options: dict | None = None
) -> list[dict]:
    """Return all events, optionally filtered by a query substring."""
    options = options or {}
    validated = assert_memory_identity(identity)
    keys = build_memory_keys(validated)
    events_key = keys["eventsKey"]

    if _redis_client is not None:
        rows = await _redis_client.lrange(events_key, 0, -1)
    else:
        rows = _get_list(events_key)

    parsed = [json.loads(item) for item in rows]

    if not query:
        return parsed

    q = query.lower()
    max_items = options.get("maxItems", 100)
    return [
        event
        for event in parsed
        if q in json.dumps(event, default=str).lower()
    ][:max_items]


async def archive_event(identity: dict, event: dict) -> bool:
    """Archive a memory event."""
    validated = assert_memory_identity(identity)
    keys = build_memory_keys(validated)
    archive_key = keys["archiveKey"]
    serialized = json.dumps(event, default=str)

    if _redis_client is not None:
        await _redis_client.rpush(archive_key, serialized)
    else:
        curr = _get_list(archive_key)
        curr.append(serialized)
        _set_list(archive_key, curr)

    return True


def __reset_for_tests() -> None:
    """Clear the in-memory store (for tests only)."""
    _in_memory_store.clear()
