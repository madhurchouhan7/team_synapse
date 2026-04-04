"""
Reliability policy with timeout and retry for agent invocations.
Converted from shared/reliabilityPolicy.js — identical logic.
"""

import asyncio
from typing import Any, Callable, Awaitable


class TimeoutError(Exception):
    """Raised when an agent invocation exceeds its timeout budget."""
    def __init__(self, label: str, timeout_ms: int):
        super().__init__(f"{label} timed out after {timeout_ms}ms")
        self.code = "ETIMEDOUT"


async def _with_timeout(
    operation: Callable[[], Awaitable[Any]],
    label: str,
    timeout_ms: int,
) -> Any:
    try:
        return await asyncio.wait_for(
            operation(),
            timeout=timeout_ms / 1000.0,
        )
    except asyncio.TimeoutError:
        raise TimeoutError(label, timeout_ms)


async def invoke_with_policy(
    *,
    label: str,
    operation: Callable[[], Awaitable[Any]],
    fallback_value: Any,
    retries: int = 1,
    timeout_ms: int = 4000,
) -> dict:
    """
    Invoke an async operation with retry + timeout policies.
    Returns a dict with result, degraded flag, attempt count, and error.
    """
    max_attempts = max(1, retries + 1)
    last_error: Exception | None = None

    for attempt in range(1, max_attempts + 1):
        try:
            result = await _with_timeout(operation, label, timeout_ms)
            return {
                "result": result,
                "degraded": False,
                "attempts": attempt,
                "error": None,
            }
        except Exception as exc:
            last_error = exc

    return {
        "result": fallback_value,
        "degraded": True,
        "attempts": max_attempts,
        "error": last_error,
    }
