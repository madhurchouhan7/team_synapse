"""
Debate and consensus engine for multi-agent quality gating.
Converted from shared/debateConsensus.js — identical logic.
"""

from typing import Any

DEFAULT_ROLE_WEIGHTS: dict[str, float] = {
    "analyst": 0.35,
    "strategist": 0.35,
    "copywriter": 0.3,
}


def _normalize_reflections(reflections: list[dict] | None = None) -> list[dict]:
    if not isinstance(reflections, list):
        return []

    result = []
    for item in reflections:
        if not isinstance(item, dict):
            continue
        role = str(item.get("role", "unknown"))
        if role == "unknown":
            continue
        score = item.get("score", 0)
        score = score if isinstance(score, (int, float)) and not (score != score) else 0  # NaN check
        result.append({
            "role": role,
            "score": score,
            "approved": bool(item.get("approved")),
            "issues": item.get("issues", []) if isinstance(item.get("issues"), list) else [],
        })
    return result


def _weighted_average_score(reflections: list[dict] | None = None) -> int:
    normalized = _normalize_reflections(reflections)
    if not normalized:
        return 0

    weighted_sum = 0.0
    total_weight = 0.0

    for reflection in normalized:
        weight = DEFAULT_ROLE_WEIGHTS.get(
            reflection["role"], 1 / max(len(normalized), 1)
        )
        weighted_sum += reflection["score"] * weight
        total_weight += weight

    return round(weighted_sum / max(total_weight, 1))


def _build_votes(reflections: list[dict] | None = None, round_num: int = 1) -> list[dict]:
    return [
        {
            "role": r["role"],
            "confidence": max(0, min(100, round(r["score"]))),
            "stance": "approve" if r["approved"] else "revise",
            "rationale": (
                f"round-{round_num}:validated"
                if len(r["issues"]) == 0
                else f"round-{round_num}:issues={len(r['issues'])}"
            ),
        }
        for r in _normalize_reflections(reflections)
    ]


def _resolve_vote_decision(votes: list[dict] | None = None) -> dict:
    votes = votes if isinstance(votes, list) else []
    weighted = {"approve": 0.0, "revise": 0.0}

    for vote in votes:
        role_weight = DEFAULT_ROLE_WEIGHTS.get(vote.get("role", ""), 0.33)
        confidence = vote.get("confidence", 0)
        confidence = confidence if isinstance(confidence, (int, float)) else 0
        stance = "approve" if vote.get("stance") == "approve" else "revise"
        weighted[stance] += role_weight * confidence

    delta = abs(weighted["approve"] - weighted["revise"])
    if delta <= 1:
        priority = ["analyst", "strategist", "copywriter"]
        for role in priority:
            role_vote = next((v for v in votes if v.get("role") == role), None)
            if role_vote:
                return {
                    "stance": role_vote.get("stance", "revise"),
                    "tieBreakApplied": True,
                    "tieBreakRule": f"priority:{role}",
                    "weighted": weighted,
                }

    return {
        "stance": "approve" if weighted["approve"] >= weighted["revise"] else "revise",
        "tieBreakApplied": False,
        "tieBreakRule": None,
        "weighted": weighted,
    }


def _apply_round_adjustments(
    *, base_score: int, issue_count: int, challenge_count: int, round_num: int
) -> int:
    issue_penalty = max(0, issue_count * 4 - round_num * 2)
    challenge_penalty = max(0, challenge_count * 3 - round_num * 2)
    round_recovery = round_num * 3
    adjusted = base_score - issue_penalty - challenge_penalty + round_recovery
    return max(0, min(100, round(adjusted)))


def run_debate_and_consensus(
    *,
    reflections: list[dict] | None = None,
    validation_issues: list | None = None,
    challenges: list | None = None,
    max_rounds: int = 2,
    min_quality_score: int = 85,
) -> dict:
    """
    Run the debate-and-consensus quality gate.
    Returns final quality score, gate status, consensus log, and decision.
    """
    reflections = reflections or []
    validation_issues = validation_issues or []
    challenges = challenges or []

    issue_count = len(validation_issues)
    challenge_count = len(challenges)
    base_score = _weighted_average_score(reflections)

    consensus_log: list[dict] = []
    final_score = _apply_round_adjustments(
        base_score=base_score,
        issue_count=issue_count,
        challenge_count=challenge_count,
        round_num=1,
    )

    consensus_log.append({
        "round": 1,
        "votes": _build_votes(reflections, 1),
        "qualityScore": final_score,
        "unresolvedChallenges": challenge_count,
        "unresolvedIssues": issue_count,
    })

    rounds = 1
    while rounds < max_rounds and final_score < min_quality_score:
        rounds += 1
        final_score = _apply_round_adjustments(
            base_score=base_score,
            issue_count=issue_count,
            challenge_count=challenge_count,
            round_num=rounds,
        )
        consensus_log.append({
            "round": rounds,
            "votes": _build_votes(reflections, rounds),
            "qualityScore": final_score,
            "unresolvedChallenges": max(0, challenge_count - (rounds - 1)),
            "unresolvedIssues": max(0, issue_count - (rounds - 1)),
        })

    final_round = consensus_log[-1] if consensus_log else {"votes": []}
    decision = _resolve_vote_decision(final_round.get("votes", []))

    return {
        "finalQualityScore": final_score,
        "debateRounds": rounds,
        "gatePassed": final_score >= min_quality_score,
        "consensusLog": consensus_log,
        "minQualityScore": min_quality_score,
        "decision": decision,
        "unresolvedRoute": "publish" if final_score >= min_quality_score else "safe_fallback",
    }
