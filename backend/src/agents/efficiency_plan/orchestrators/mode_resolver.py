"""
Orchestration mode resolver.
Converted from orchestrators/modeResolver.js — identical logic.
"""

from typing import Any, Optional

from ..exceptions import ApiError

ALLOWED_MODES = ["legacy", "collaborative"]


def _has_disallowed_mode_inputs(body: dict, query: dict) -> bool:
    return (
        "aiMode" in body
        or "mode" in body
        or "aiMode" in query
        or "mode" in query
    )


def _read_header_mode(headers: dict) -> Optional[str]:
    mode = headers.get("x-ai-mode")
    if mode is None or mode == "":
        return None
    return str(mode).strip().lower()


def resolve_orchestration_mode(
    *,
    body: dict | None = None,
    query: dict | None = None,
    headers: dict | None = None,
    node_env: str | None = None,
) -> dict[str, str]:
    """
    Determine the orchestration mode from request context.
    For FastAPI, pass body, query params, and headers directly.
    Returns {"requestedMode": ..., "executionPath": ...}.
    """
    import os

    body = body or {}
    query = query or {}
    headers = headers or {}

    if _has_disallowed_mode_inputs(body, query):
        raise ApiError(
            400,
            "Mode must be provided only via x-ai-mode header. "
            "Body/query mode fields are not allowed in this phase.",
        )

    header_mode = _read_header_mode(headers)

    if header_mode is not None and header_mode not in ALLOWED_MODES:
        raise ApiError(400, "Invalid x-ai-mode. Allowed values: legacy, collaborative")

    env = (node_env or os.environ.get("NODE_ENV", "development")).lower()
    default_mode = "legacy" if env == "production" else "collaborative"
    selected_mode = header_mode or default_mode

    return {
        "requestedMode": selected_mode,
        "executionPath": selected_mode,
    }
