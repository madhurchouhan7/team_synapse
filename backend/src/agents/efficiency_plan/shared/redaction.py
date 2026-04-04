"""
Redaction utility for sanitising sensitive fields in memory payloads.
Converted from shared/redaction.js — identical logic.
"""

import hashlib
import json
from typing import Any

SENSITIVE_KEYS = frozenset([
    "token",
    "apiKey",
    "password",
    "secret",
    "authorization",
])


def _tokenize(value: Any) -> str:
    normalized = value if isinstance(value, str) else json.dumps(value, default=str)
    digest = hashlib.sha256(normalized.encode()).hexdigest()[:12]
    return f"[TOKENIZED:{digest}]"


def redact_memory_payload(payload: Any) -> Any:
    """Recursively redact sensitive keys in a payload dict/list."""
    if isinstance(payload, list):
        return [redact_memory_payload(item) for item in payload]

    if isinstance(payload, dict):
        out = {}
        for key, value in payload.items():
            if key in SENSITIVE_KEYS:
                out[key] = _tokenize(value)
            else:
                out[key] = redact_memory_payload(value)
        return out

    return payload
