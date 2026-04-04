"""
Response envelope builder for dual-path orchestration.
Converted from orchestrators/responseEnvelope.js — identical logic.
"""

import math
from typing import Any, Optional


def build_plan_response_envelope(
    *,
    final_plan: dict | None = None,
    requested_mode: str = "unspecified",
    execution_path: str = "unknown",
    request_id: str | None = None,
    run_id: str | None = None,
    thread_id: str | None = None,
    quality_score: float | None = None,
    debate_rounds: int | None = None,
    revision_count: int | None = None,
    validation_issue_count: int | None = None,
    challenge_count: int | None = None,
    role_retry_budgets: dict | None = None,
    quality_gate: dict | None = None,
    consensus_round_count: int | None = None,
    consensus_rationale: list | None = None,
    safe_fallback_activated: bool = False,
    consensus_decision: dict | None = None,
    unresolved_route: str | None = None,
    degradation_events: list | None = None,
) -> dict:
    """Build the standardised plan response envelope with orchestration metadata."""
    metadata: dict[str, Any] = {
        "executionPath": execution_path,
        "requestedMode": requested_mode,
        "requestId": request_id,
        "orchestrationVersion": "v2-phase2",
        "qualityScore": quality_score,
        "debateRounds": (
            debate_rounds
            if isinstance(debate_rounds, (int, float)) and math.isfinite(debate_rounds)
            else 0
        ),
    }

    if request_id or run_id or thread_id:
        metadata["memoryTrace"] = {
            "requestId": request_id,
            "runId": run_id,
            "threadId": thread_id,
        }

    def _is_finite(val: Any) -> bool:
        return isinstance(val, (int, float)) and math.isfinite(val)

    if (
        _is_finite(revision_count)
        or _is_finite(validation_issue_count)
        or _is_finite(challenge_count)
    ):
        metadata["phase4"] = {
            "revisionCount": revision_count if _is_finite(revision_count) else 0,
            "validationIssueCount": (
                validation_issue_count if _is_finite(validation_issue_count) else 0
            ),
            "challengeCount": challenge_count if _is_finite(challenge_count) else 0,
            "roleRetryBudgets": (
                role_retry_budgets
                if isinstance(role_retry_budgets, dict)
                else {
                    "analyst": 0,
                    "strategist": 0,
                    "copywriter": 0,
                    "challengeRouting": 0,
                }
            ),
        }

    if quality_gate or _is_finite(consensus_round_count):
        metadata["phase5"] = {
            "qualityGate": (
                quality_gate
                if isinstance(quality_gate, dict)
                else {"minScore": 85, "passed": False}
            ),
            "consensusRoundCount": (
                consensus_round_count if _is_finite(consensus_round_count) else 0
            ),
            "consensusRationale": (
                consensus_rationale if isinstance(consensus_rationale, list) else []
            ),
            "safeFallbackActivated": bool(safe_fallback_activated),
            "consensusDecision": (
                consensus_decision
                if isinstance(consensus_decision, dict)
                else {
                    "stance": "revise",
                    "tieBreakApplied": False,
                    "tieBreakRule": None,
                }
            ),
            "unresolvedRoute": unresolved_route or "safe_fallback",
        }

    if isinstance(degradation_events, list) and len(degradation_events) > 0:
        metadata["phase6"] = {
            "degraded": True,
            "degradedAgentCount": len(degradation_events),
            "degradationEvents": degradation_events,
        }

    return {
        "finalPlan": final_plan,
        "metadata": metadata,
    }
