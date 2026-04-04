"""
Memory service — write, read recent, and read historical events.
Converted from shared/memoryService.js — identical logic.
"""

import math
import random
import string
import time
from typing import Any

from ..exceptions import ApiError
from .memory_keys import assert_memory_identity
from .memory_schema import validate_memory_event
from .redaction import redact_memory_payload
from . import memory_store_redis as memory_store


def _build_revision_id() -> str:
    random_part = "".join(random.choices(string.ascii_lowercase + string.digits, k=6))
    return f"rev-{int(time.time() * 1000)}-{random_part}"


async def write_event(input_data: dict | None = None) -> dict:
    """Validate and persist a memory event."""
    input_data = input_data or {}
    identity = assert_memory_identity(input_data)

    from datetime import datetime, timezone

    event = {
        **input_data,
        **identity,
        "revisionId": input_data.get("revisionId") or _build_revision_id(),
        "timestamp": input_data.get("timestamp") or datetime.now(timezone.utc).isoformat(),
        "payload": redact_memory_payload(input_data.get("payload", {})),
    }

    parsed = validate_memory_event(event)
    if not parsed["success"]:
        error = parsed["error"]
        message = str(error)
        raise ApiError(400, message)

    return await memory_store.append_event(identity, parsed["data"])


async def get_recent(scope: dict, *, limit: int = 12) -> list[dict]:
    """Get the most recent events for a scope."""
    identity = assert_memory_identity(scope)
    return await memory_store.list_recent_events(identity, limit)


async def get_historical(
    scope: dict, query: str = "", options: dict | None = None
) -> list[dict]:
    """Get historical events, optionally filtered by query."""
    identity = assert_memory_identity(scope)
    return await memory_store.list_historical_events(identity, query, options)
