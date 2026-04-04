"""
Retrieval planner for composing agent memory context.
Converted from shared/retrievalPlanner.js — identical logic.
"""

import json
import math
from typing import Any

# Optional tiktoken import (mirrors the JS optional js-tiktoken require)
try:
    import tiktoken

    _encoding = tiktoken.encoding_for_model("gpt-4o-mini")
except Exception:
    tiktoken = None
    _encoding = None


def _rank_historical_events(events: list[dict], query: str) -> list[dict]:
    if not query:
        return events

    q = query.lower()
    scored = []
    for idx, event in enumerate(events):
        text = json.dumps(event, default=str).lower()
        lexical = 2 if q in text else 0
        recency = 1 / (idx + 1)
        score = lexical + recency
        if score >= 2:
            scored.append((event, score))

    scored.sort(key=lambda x: x[1], reverse=True)
    return [entry[0] for entry in scored]


def _estimate_tokens(text: str) -> int:
    if _encoding is not None:
        try:
            return len(_encoding.encode(text))
        except Exception:
            pass

    return math.ceil(len(text) / 4)


def _select_within_budget(
    items: list[Any], token_budget: int
) -> dict:
    selected: list[Any] = []
    used = 0

    for item in items:
        cost = _estimate_tokens(json.dumps(item, default=str))
        if used + cost > token_budget:
            break
        selected.append(item)
        used += cost

    return {"selected": selected, "tokenUsage": used}


def compose_agent_context(
    *,
    recent_events: list[dict] | None = None,
    historical_events: list[dict] | None = None,
    query: str = "",
    token_budget: int = 6000,
    recent_limit: int = 12,
) -> dict:
    """
    Merge recent + ranked historical events, trim to token budget.
    Returns dict with contextEvents, tokenUsage, and usedFallback flag.
    """
    recent_events = recent_events or []
    historical_events = historical_events or []

    recent = recent_events[-recent_limit:]
    ranked_historical = _rank_historical_events(historical_events, query)

    merged = recent + ranked_historical
    budget_result = _select_within_budget(merged, token_budget)

    has_historical = len(budget_result["selected"]) > len(recent)
    if not has_historical:
        fallback = _select_within_budget(recent, token_budget)
        return {
            "contextEvents": fallback["selected"],
            "tokenUsage": fallback["tokenUsage"],
            "usedFallback": True,
        }

    return {
        "contextEvents": budget_result["selected"],
        "tokenUsage": budget_result["tokenUsage"],
        "usedFallback": False,
    }
