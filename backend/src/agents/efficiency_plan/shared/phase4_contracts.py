"""
Phase 4 validation contracts, normalization, hallucination detection,
cross-agent challenges, and reflections.
Converted from shared/phase4Contracts.js — identical logic.
Uses Pydantic instead of Zod for schema validation.
"""

import math
import re
from datetime import datetime, timezone
from typing import Any, Optional, Union

from pydantic import BaseModel, Field, ValidationError

# ── Constants ──────────────────────────────────────────────────────────
MAX_REVISION_ATTEMPTS = 2
MIN_STRATEGY_COUNT = 4

DEFAULT_STRATEGY_TEMPLATES: list[dict] = [
    {
        "id": "baseline_strategy_1",
        "actionSummary": "Optimize cooling runtime windows",
        "fullDescription": (
            "Run AC in shorter cycles and pair with fan circulation "
            "to reduce compressor load."
        ),
    },
    {
        "id": "baseline_strategy_2",
        "actionSummary": "Shift heavy appliances to off-peak",
        "fullDescription": (
            "Use washing machine and water heater during lower-demand "
            "windows to flatten daily peaks."
        ),
    },
    {
        "id": "baseline_strategy_3",
        "actionSummary": "Cut standby and idle loads",
        "fullDescription": (
            "Switch off set-top boxes, chargers, and kitchen devices "
            "when inactive to avoid passive draw."
        ),
    },
    {
        "id": "baseline_strategy_4",
        "actionSummary": "Tune thermostat and fan settings",
        "fullDescription": (
            "Increase thermostat by 1-2C and maintain fan speed for "
            "comfort with lower total energy use."
        ),
    },
    {
        "id": "baseline_strategy_5",
        "actionSummary": "Improve daily usage discipline",
        "fullDescription": (
            "Track one high-consumption appliance daily and cap "
            "unnecessary runtime by 15-20 minutes."
        ),
    },
]


# ── Pydantic Schemas (replacing Zod) ───────────────────────────────────
class AnomalySchema(BaseModel):
    id: str = Field(..., min_length=1)
    item: str = Field(..., min_length=1)
    description: str = Field(..., min_length=1)
    rupeeCostImpact: float = Field(..., ge=0)


class StrategySchema(BaseModel):
    id: str = Field(..., min_length=1)
    actionSummary: str = Field(..., min_length=1)
    fullDescription: str = Field(..., min_length=1)
    projectedSavings: float = Field(..., ge=0)


class KeyActionSchema(BaseModel):
    action: str = Field(..., min_length=1)
    impact: str = Field(..., min_length=1)
    estimatedSaving: Optional[Union[str, float]] = None


class FinalPlanSchema(BaseModel):
    planType: str = Field(..., min_length=1)
    title: str = Field(..., min_length=1)
    status: str = Field(..., min_length=1)
    summary: str = Field(..., min_length=1)
    keyActions: list[KeyActionSchema] = Field(..., min_length=1)
    quickWins: Optional[list[str]] = None
    monthlyTip: Optional[str] = None


# ── Helpers ────────────────────────────────────────────────────────────
def _parse_estimated_saving(value: Any) -> float:
    if isinstance(value, (int, float)) and math.isfinite(value):
        return float(value)

    if isinstance(value, str):
        normalized = re.sub(r"[^0-9.\-]", "", value)
        try:
            parsed = float(normalized)
            return parsed if math.isfinite(parsed) else 0.0
        except (ValueError, TypeError):
            return 0.0

    return 0.0


# ── Normalizers ────────────────────────────────────────────────────────
def normalize_anomalies(input_data: list | None = None) -> list[dict]:
    """Normalize raw anomaly data, ensuring every item has valid fields."""
    items = input_data if isinstance(input_data, list) else []

    normalized = []
    for index, item in enumerate(items):
        if not isinstance(item, dict):
            continue
        raw_cost = item.get("rupeeCostImpact", 0)
        try:
            cost = max(0.0, float(raw_cost))
        except (ValueError, TypeError):
            cost = 0.0

        entry = {
            "id": str(item.get("id", f"anomaly_{index + 1}")),
            "item": str(item.get("item", "General Usage")),
            "description": str(
                item.get("description", "Detected unusual consumption pattern.")
            ),
            "rupeeCostImpact": cost,
        }
        if entry["id"] and entry["item"] and entry["description"]:
            normalized.append(entry)

    if normalized:
        return normalized

    return [
        {
            "id": "baseline_anomaly",
            "item": "General Household Load",
            "description": "Baseline anomaly generated due to missing analyst output.",
            "rupeeCostImpact": 150,
        }
    ]


def normalize_strategies(
    input_data: list | None = None, anomalies: list | None = None
) -> list[dict]:
    """Normalize strategies, supplement to MIN_STRATEGY_COUNT if needed."""
    anomaly_budget = max(
        1.0,
        sum(item.get("rupeeCostImpact", 0) for item in normalize_anomalies(anomalies)),
    )

    items = input_data if isinstance(input_data, list) else []

    normalized = []
    for index, item in enumerate(items):
        if not isinstance(item, dict):
            continue
        raw_savings = item.get("projectedSavings", 0)
        try:
            savings = max(0.0, float(raw_savings))
        except (ValueError, TypeError):
            savings = 0.0

        entry = {
            "id": str(item.get("id", f"strategy_{index + 1}")),
            "actionSummary": str(
                item.get("actionSummary", "Reduce non-essential runtime")
            ),
            "fullDescription": str(
                item.get(
                    "fullDescription",
                    "Shift high-consumption usage to shorter windows and avoid idle loads.",
                )
            ),
            "projectedSavings": savings,
        }
        if len(entry["actionSummary"]) > 0:
            normalized.append(entry)

    # Cap savings to 1.2x anomaly budget
    bounded = [
        {**item, "projectedSavings": min(item["projectedSavings"], anomaly_budget * 1.2)}
        for item in normalized
    ]

    min_required = min(MIN_STRATEGY_COUNT, len(DEFAULT_STRATEGY_TEMPLATES))
    if len(bounded) >= min_required:
        return bounded

    fallback_savings = max(50, round(anomaly_budget * 0.15))
    existing_summaries = {item["actionSummary"].lower() for item in bounded}
    supplemented = list(bounded)

    for template in DEFAULT_STRATEGY_TEMPLATES:
        if len(supplemented) >= min_required:
            break
        if template["actionSummary"].lower() in existing_summaries:
            continue
        supplemented.append({
            "id": f"{template['id']}_{len(supplemented) + 1}",
            "actionSummary": template["actionSummary"],
            "fullDescription": template["fullDescription"],
            "projectedSavings": fallback_savings,
        })

    return supplemented


def build_fallback_final_plan(strategies: list | None = None) -> dict:
    """Build a safe fallback final plan from strategies."""
    safe_strategies = normalize_strategies(strategies, [])
    rupees = sum(item["projectedSavings"] for item in safe_strategies)

    return {
        "planType": "efficiency",
        "title": "Collaborative Efficiency Plan",
        "status": "draft",
        "summary": "This plan was generated with validated specialist outputs.",
        "estimatedCurrentMonthlyCost": 0,
        "estimatedSavingsIfFollowed": {
            "units": 0,
            "rupees": rupees,
            "percentage": 0,
        },
        "efficiencyScore": None,
        "keyActions": [
            {
                "priority": "high",
                "appliance": "General Household",
                "action": item["actionSummary"],
                "impact": item["fullDescription"],
                "estimatedSaving": item["projectedSavings"],
            }
            for item in safe_strategies
        ],
        "slabAlert": {
            "isInDangerZone": False,
            "currentSlab": "unknown",
            "warning": "",
        },
        "quickWins": ["Use shorter appliance cycles", "Avoid idle standby loads"],
        "monthlyTip": "Review your highest runtime appliance weekly.",
    }


# ── Validators ─────────────────────────────────────────────────────────
def validate_anomalies(anomalies: list | None = None) -> dict:
    anomalies = anomalies or []
    try:
        for item in anomalies:
            AnomalySchema(**item)
        return {"ok": True, "issues": []}
    except ValidationError as exc:
        issues = [
            f"analyst:{'.'.join(str(p) for p in e['loc'])}:{e['msg']}"
            for e in exc.errors()
        ]
        return {"ok": False, "issues": issues}


def validate_strategies(strategies: list | None = None) -> dict:
    strategies = strategies or []
    try:
        for item in strategies:
            StrategySchema(**item)
        return {"ok": True, "issues": []}
    except ValidationError as exc:
        issues = [
            f"strategist:{'.'.join(str(p) for p in e['loc'])}:{e['msg']}"
            for e in exc.errors()
        ]
        return {"ok": False, "issues": issues}


def validate_final_plan(final_plan: dict | None = None) -> dict:
    final_plan = final_plan or {}
    try:
        FinalPlanSchema(**final_plan)
        return {"ok": True, "issues": []}
    except ValidationError as exc:
        issues = [
            f"copywriter:{'.'.join(str(p) for p in e['loc'])}:{e['msg']}"
            for e in exc.errors()
        ]
        return {"ok": False, "issues": issues}


# ── Hallucination & Cross-Agent Checks ─────────────────────────────────
def detect_hallucination_risks(
    anomalies: list | None = None,
    strategies: list | None = None,
    final_plan: dict | None = None,
) -> list[str]:
    normalized_anomalies = normalize_anomalies(anomalies)
    anomaly_budget = sum(item["rupeeCostImpact"] for item in normalized_anomalies)
    strategy_savings = sum(
        item["projectedSavings"]
        for item in normalize_strategies(strategies, normalized_anomalies)
    )

    risks: list[str] = []
    if strategy_savings > anomaly_budget * 1.8:
        risks.append(
            f"qa:projectedSavings_excess:{strategy_savings} exceeds expected "
            f"ceiling for anomaly budget {anomaly_budget}"
        )

    if final_plan and isinstance(final_plan.get("keyActions"), list):
        plan_savings = sum(
            _parse_estimated_saving(action.get("estimatedSaving"))
            for action in final_plan["keyActions"]
        )
        if plan_savings > max(strategy_savings * 1.8, 1):
            risks.append(
                f"qa:keyActionSavings_excess:{plan_savings} exceeds "
                f"strategy savings envelope {strategy_savings}"
            )

    return risks


def build_cross_agent_challenges(
    anomalies: list | None = None,
    strategies: list | None = None,
    final_plan: dict | None = None,
) -> list[dict]:
    normalized_anomalies = normalize_anomalies(anomalies)
    normalized_strategies = normalize_strategies(strategies, normalized_anomalies)
    anomaly_budget = sum(item["rupeeCostImpact"] for item in normalized_anomalies)
    strategy_budget = sum(item["projectedSavings"] for item in normalized_strategies)

    challenges: list[dict] = []

    def make_challenge(input_data: dict, index: int) -> dict:
        return {
            "challengeId": (
                f"ch_{input_data['source']}_{input_data['target']}_"
                f"{input_data['type']}_{index + 1}"
            ),
            "severity": input_data.get("severity", "medium"),
            **input_data,
        }

    raw_strategies = strategies if isinstance(strategies, list) else []
    raw_anomalies = anomalies if isinstance(anomalies, list) else []

    if (
        (len(raw_strategies) > 0 and len(raw_anomalies) == 0)
        or (strategy_budget > 0 and anomaly_budget <= 0)
    ):
        challenges.append(
            make_challenge(
                {
                    "source": "strategist",
                    "target": "analyst",
                    "type": "missing_evidence",
                    "severity": "high",
                    "reason": "Strategies were generated without anomaly evidence.",
                    "evidence": {
                        "anomalyCount": len(raw_anomalies),
                        "strategyCount": len(raw_strategies),
                        "anomalyBudget": anomaly_budget,
                        "strategyBudget": strategy_budget,
                    },
                    "expectedCorrection": (
                        "Provide anomaly-backed evidence or reduce "
                        "projected savings before publish."
                    ),
                },
                len(challenges),
            )
        )

    if (
        final_plan
        and isinstance(final_plan.get("keyActions"), list)
        and len(final_plan["keyActions"]) < len(raw_strategies)
    ):
        challenges.append(
            make_challenge(
                {
                    "source": "copywriter",
                    "target": "strategist",
                    "type": "coverage_gap",
                    "severity": "medium",
                    "reason": (
                        "Some strategist outputs were not represented "
                        "in final keyActions."
                    ),
                    "evidence": {
                        "strategyCount": len(raw_strategies),
                        "keyActionCount": len(final_plan["keyActions"]),
                    },
                    "expectedCorrection": (
                        "Map each validated strategy to at least one keyAction."
                    ),
                },
                len(challenges),
            )
        )

    return challenges


def build_reflection(
    role: str, issues: list | None = None, challenges: list | None = None
) -> dict:
    issues = issues or []
    challenges = challenges or []

    issue_penalty = min(60, len(issues) * 20)
    challenge_penalty = min(25, len(challenges) * 5)
    score = max(0, 100 - issue_penalty - challenge_penalty)

    return {
        "role": role,
        "approved": len(issues) == 0,
        "score": score,
        "issues": issues,
        "challengeCount": len(challenges),
        "reviewedAt": datetime.now(timezone.utc).isoformat(),
    }
