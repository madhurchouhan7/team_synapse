"""
Collaborative entrypoint for Phase 2 dual-path routing.
Preserves invoke-compatibility without altering legacy graph exports.
Converted from collaborative.index.js — identical logic.
"""

import logging
import os
from datetime import datetime, timezone
from typing import Any

from .exceptions import ApiError
from .shared import memory_service
from .shared.retrieval_planner import compose_agent_context
from .analyst_node import run_analyst
from .strategist_node import run_strategist
from .copywriter_node import run_copywriter
from .shared.phase4_contracts import (
    MAX_REVISION_ATTEMPTS,
    build_cross_agent_challenges,
    build_fallback_final_plan,
    build_reflection,
    detect_hallucination_risks,
    normalize_anomalies,
    normalize_strategies,
    validate_anomalies,
    validate_strategies,
    validate_final_plan,
)
from .shared.debate_consensus import run_debate_and_consensus
from .shared.reliability_policy import invoke_with_policy

logger = logging.getLogger("wattwise.agents.collaborative")

AGENT_TIMEOUT_MS = int(os.environ.get("PHASE6_AGENT_TIMEOUT_MS", "4000"))
AGENT_RETRIES = int(os.environ.get("PHASE6_AGENT_RETRIES", "1"))


def _log_memory_event(event_data: dict) -> None:
    """Log memory read/write events (replaces loggingMiddleware.logMemoryEvent)."""
    logger.info(f"[MEMORY] {event_data.get('eventType', 'unknown')}: {event_data}")


class CollaborativePlanApp:
    """Collaborative multi-agent plan orchestrator with memory, validation, and consensus."""

    async def invoke(self, initial_state: dict | None = None) -> dict:
        initial_state = initial_state or {}
        user_data = initial_state.get("userData", {})
        memory_meta = initial_state.get("memoryMeta", {})
        identity = {
            "tenantId": memory_meta.get("tenantId"),
            "userId": memory_meta.get("userId"),
            "threadId": memory_meta.get("threadId"),
        }

        if not identity["tenantId"] or not identity["userId"] or not identity["threadId"]:
            raise ApiError(
                400,
                "Missing required memory identity keys for collaborative mode: "
                "tenantId, userId, threadId",
            )

        recent_events = await memory_service.get_recent(identity, limit=12)
        historical_events = await memory_service.get_historical(
            identity,
            memory_meta.get("query", ""),
            {"maxItems": 100},
        )
        composed = compose_agent_context(
            recent_events=recent_events,
            historical_events=historical_events,
            query=memory_meta.get("query", ""),
            token_budget=memory_meta.get("tokenBudget", 6000),
        )

        _log_memory_event({
            "eventType": "memory_read",
            "scope": f"{identity['tenantId']}:{identity['userId']}:{identity['threadId']}",
            "requestId": memory_meta.get("requestId"),
            "runId": memory_meta.get("runId"),
            "threadId": identity["threadId"],
            "tokenBudgetUsed": composed["tokenUsage"],
            "usedFallback": composed["usedFallback"],
        })

        revision_count = 0
        role_retry_budgets = {
            "analyst": 0,
            "strategist": 0,
            "copywriter": 0,
            "challengeRouting": 0,
        }
        degradation_events: list[dict] = []

        # ── Analyst ────────────────────────────────────────────────────
        analyst_call = await invoke_with_policy(
            label="analyst",
            operation=lambda: run_analyst({
                **initial_state,
                "memoryContext": composed["contextEvents"],
            }),
            fallback_value={"anomalies": []},
            retries=AGENT_RETRIES,
            timeout_ms=AGENT_TIMEOUT_MS,
        )
        analyst_out = analyst_call["result"]
        if analyst_call["degraded"]:
            degradation_events.append({
                "agent": "analyst",
                "attempts": analyst_call["attempts"],
                "reason": str(analyst_call["error"]) if analyst_call["error"] else "unknown",
            })

        anomalies = normalize_anomalies(analyst_out.get("anomalies", []))
        analyst_validation = validate_anomalies(anomalies)

        while not analyst_validation["ok"] and revision_count < MAX_REVISION_ATTEMPTS:
            anomalies = normalize_anomalies(anomalies)
            analyst_validation = validate_anomalies(anomalies)
            role_retry_budgets["analyst"] += 1
            revision_count += 1

        # ── Strategist ─────────────────────────────────────────────────
        strategist_call = await invoke_with_policy(
            label="strategist",
            operation=lambda: run_strategist({
                **initial_state,
                "anomalies": anomalies,
                "memoryContext": composed["contextEvents"],
            }),
            fallback_value={"strategies": []},
            retries=AGENT_RETRIES,
            timeout_ms=AGENT_TIMEOUT_MS,
        )
        strategist_out = strategist_call["result"]
        if strategist_call["degraded"]:
            degradation_events.append({
                "agent": "strategist",
                "attempts": strategist_call["attempts"],
                "reason": str(strategist_call["error"]) if strategist_call["error"] else "unknown",
            })

        strategies = normalize_strategies(
            strategist_out.get("strategies", []),
            anomalies,
        )
        strategist_validation = validate_strategies(strategies)

        while not strategist_validation["ok"] and revision_count < MAX_REVISION_ATTEMPTS:
            strategies = normalize_strategies(strategies, anomalies)
            strategist_validation = validate_strategies(strategies)
            role_retry_budgets["strategist"] += 1
            revision_count += 1

        # ── Copywriter ─────────────────────────────────────────────────
        copywriter_call = await invoke_with_policy(
            label="copywriter",
            operation=lambda: run_copywriter({
                **initial_state,
                "anomalies": anomalies,
                "strategies": strategies,
                "memoryContext": composed["contextEvents"],
            }),
            fallback_value={"finalPlan": build_fallback_final_plan(strategies)},
            retries=AGENT_RETRIES,
            timeout_ms=AGENT_TIMEOUT_MS,
        )
        copywriter_out = copywriter_call["result"]
        if copywriter_call["degraded"]:
            degradation_events.append({
                "agent": "copywriter",
                "attempts": copywriter_call["attempts"],
                "reason": str(copywriter_call["error"]) if copywriter_call["error"] else "unknown",
            })

        final_plan = copywriter_out.get("finalPlan") or build_fallback_final_plan(strategies)
        copywriter_validation = validate_final_plan(final_plan)

        if not copywriter_validation["ok"] and revision_count < MAX_REVISION_ATTEMPTS:
            final_plan = build_fallback_final_plan(strategies)
            copywriter_validation = validate_final_plan(final_plan)
            role_retry_budgets["copywriter"] += 1
            revision_count += 1

        # ── Cross-agent checks ─────────────────────────────────────────
        hallucination_risks = detect_hallucination_risks(anomalies, strategies, final_plan)
        challenges = build_cross_agent_challenges(anomalies, strategies, final_plan)
        validation_issues: list[str] = [
            *analyst_validation["issues"],
            *strategist_validation["issues"],
            *copywriter_validation["issues"],
            *hallucination_risks,
        ]

        if degradation_events:
            validation_issues.extend(
                f"ops:degraded:{item['agent']}:attempts_{item['attempts']}:{item['reason']}"
                for item in degradation_events
            )

        while challenges and revision_count < MAX_REVISION_ATTEMPTS:
            strategies = normalize_strategies(strategies, anomalies)
            final_plan = build_fallback_final_plan(strategies)
            copywriter_validation = validate_final_plan(final_plan)
            role_retry_budgets["challengeRouting"] += 1
            revision_count += 1

            hallucination_risks = detect_hallucination_risks(anomalies, strategies, final_plan)
            challenges = build_cross_agent_challenges(anomalies, strategies, final_plan)
            validation_issues = [
                *analyst_validation["issues"],
                *strategist_validation["issues"],
                *copywriter_validation["issues"],
                *hallucination_risks,
            ]

        # ── Reflections ────────────────────────────────────────────────
        analyst_reflection = build_reflection(
            "analyst", analyst_validation["issues"], challenges
        )
        strategist_reflection = build_reflection(
            "strategist",
            [*strategist_validation["issues"], *hallucination_risks],
            challenges,
        )
        copywriter_reflection = build_reflection(
            "copywriter", copywriter_validation["issues"], challenges
        )
        reflections = [analyst_reflection, strategist_reflection, copywriter_reflection]

        # ── Debate & Consensus ─────────────────────────────────────────
        consensus = run_debate_and_consensus(
            reflections=reflections,
            validation_issues=validation_issues,
            challenges=challenges,
            max_rounds=2,
            min_quality_score=85,
        )

        quality_score = consensus["finalQualityScore"]
        quality_gate = {
            "minScore": consensus["minQualityScore"],
            "passed": consensus["gatePassed"],
        }
        consensus_decision = consensus["decision"]

        safe_fallback_activated = False
        if not quality_gate["passed"]:
            validation_issues.append(
                f"qa:quality_gate_failed:score_{quality_score}_min_{quality_gate['minScore']}"
            )
            final_plan = {
                **build_fallback_final_plan(strategies),
                "status": "safe_fallback",
                "summary": (
                    "Safe fallback activated after unresolved debate. "
                    "Review and refine this plan before publish."
                ),
            }
            safe_fallback_activated = True

        # ── Persist memory event ───────────────────────────────────────
        summary = (
            final_plan.get("summary")
            if final_plan
            else "Collaborative plan generated with reflection and validation gates."
        )

        memory_event = await memory_service.write_event({
            **identity,
            "eventType": "agent_turn",
            "agentId": "collaborative-orchestrator",
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "sourceType": "llm",
            "evidenceRefs": [{"id": "context:collaborative", "type": "context"}],
            "revisionId": f"rev-{int(datetime.now(timezone.utc).timestamp() * 1000)}",
            "confidenceScore": 0.8,
            "requestId": memory_meta.get("requestId"),
            "runId": memory_meta.get("runId"),
            "payload": {
                "summary": summary,
                "mode": "collaborative",
                "userData": user_data,
                "anomaliesCount": len(anomalies),
                "strategiesCount": len(strategies),
                "revisionCount": revision_count,
                "roleRetryBudgets": role_retry_budgets,
                "qualityScore": quality_score,
                "qualityGate": quality_gate,
                "safeFallbackActivated": safe_fallback_activated,
                "consensusRounds": consensus["debateRounds"],
                "consensusDecision": consensus_decision,
                "unresolvedRoute": consensus["unresolvedRoute"],
                "degradationEvents": degradation_events,
                "validationIssues": validation_issues,
                "challenges": challenges,
            },
        })

        _log_memory_event({
            "eventType": "memory_write",
            "scope": f"{identity['tenantId']}:{identity['userId']}:{identity['threadId']}",
            "revisionId": memory_event.get("revisionId"),
            "requestId": memory_meta.get("requestId"),
            "runId": memory_meta.get("runId"),
            "threadId": identity["threadId"],
            "tokenBudgetUsed": composed["tokenUsage"],
            "usedFallback": composed["usedFallback"],
        })

        return {
            "userData": user_data,
            "weatherContext": initial_state.get("weatherContext", ""),
            "memoryContext": composed["contextEvents"],
            "memoryEventRefs": [memory_event.get("revisionId", "")],
            "anomalies": anomalies,
            "strategies": strategies,
            "finalPlan": final_plan,
            "agentReflections": reflections,
            "validationIssues": validation_issues,
            "crossAgentChallenges": challenges,
            "revisionCount": revision_count,
            "roleRetryBudgets": role_retry_budgets,
            "qualityScore": quality_score,
            "debateRounds": consensus["debateRounds"],
            "consensusLog": consensus["consensusLog"],
            "qualityGate": quality_gate,
            "consensusDecision": consensus_decision,
            "unresolvedRoute": consensus["unresolvedRoute"],
            "safeFallbackActivated": safe_fallback_activated,
            "degradationEvents": degradation_events,
            "runId": memory_meta.get("runId"),
            "threadId": identity["threadId"],
        }


collaborative_plan_app = CollaborativePlanApp()
