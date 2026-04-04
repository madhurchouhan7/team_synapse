"""
ROI Calculator Node — Node 2 of Upgrade Advisor workflow.

Uses Gemini (via LangChain) to generate human-friendly upgrade recommendations
grounded in the appliance profiles computed by the Profiler node.
Also takes weather context into account (e.g. peak summer = AC upgrade priority).
"""

import json
import logging
import os
import re
from typing import Any

from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.messages import HumanMessage, SystemMessage

logger = logging.getLogger("wattwise.agents.upgrade_advisor.roi_calculator")

# ── LLM (Gemini 2.0 Flash) ────────────────────────────────────────────
llm = ChatGoogleGenerativeAI(
    model="gemini-2.0-flash",
    google_api_key=os.environ.get("GEMINI_API_KEY", "dummy"),
    temperature=0.3,
)

SYSTEM_PROMPT = SystemMessage(content=(
    "You are a financial and energy advisor for Indian households.\n"
    "Given appliance upgrade profiles (with calculated ROI data), weather context, "
    "and past bill history, generate 3–5 prioritised, actionable upgrade recommendations.\n\n"
    "RULES:\n"
    "1. Only recommend appliances where isUpgradeable=true and paybackMonths < 48.\n"
    "2. Prioritise by: (a) highest annual saving, (b) shortest payback, (c) weather relevance.\n"
    "3. Be specific: name the appliance, current star rating, recommended star, capex, ROI.\n"
    "4. If weather is hot (>35°C or summer), prioritise AC upgrades first.\n"
    "5. RETURN ONLY a strict JSON array — no markdown.\n\n"
    "OUTPUT SCHEMA (JSON Array):\n"
    "[\n"
    "  {\n"
    '    "rank": 1,\n'
    '    "applianceId": "string",\n'
    '    "title": "Air Conditioner (1.5 Ton)",\n'
    '    "currentStarRating": "2",\n'
    '    "recommendedStarRating": "5",\n'
    '    "upgradeCapexInr": 38000,\n'
    '    "monthlySavingsInr": 450,\n'
    '    "annualSavingsInr": 5400,\n'
    '    "paybackMonths": 7.0,\n'
    '    "headline": "Short punchy headline (<=60 chars)",\n'
    '    "rationale": "One sentence blunt reason why this upgrade makes financial sense now.",\n'
    '    "urgency": "high | medium | low"\n'
    "  }\n"
    "]"
))


async def run_roi_calculator(state: dict[str, Any]) -> dict[str, Any]:
    """Generate LLM-powered, weather-aware ROI recommendations from appliance profiles."""
    logger.info("--> [UpgradeAdvisor] ROI Calculator Node Executing")

    profiles = state.get("applianceProfiles") or []
    weather = state.get("weatherContext", "No weather data provided.")
    bills = state.get("bills") or []
    issues = list(state.get("validationIssues") or [])

    # Filter to upgradeable appliances only before sending to LLM
    upgradeable = [p for p in profiles if p.get("isUpgradeable")]

    if not upgradeable:
        logger.info("--> [UpgradeAdvisor] ROI Calculator: no upgradeable appliances found.")
        issues.append("roi_calculator:no_upgradeable_appliances")
        return {"roiEstimates": [], "validationIssues": issues}

    try:
        if not os.environ.get("GEMINI_API_KEY"):
            logger.info("--> [UpgradeAdvisor] ROI Calculator: mock fallback (no GEMINI_API_KEY).")
            return _mock_roi_estimates(upgradeable, issues)

        # Summarise bill context
        bill_summary = _summarise_bills(bills)

        user_message = HumanMessage(
            content=(
                f"Current Weather: {weather}\n\n"
                f"Bill Summary (past bills): {bill_summary}\n\n"
                f"Appliance Upgrade Profiles:\n"
                f"{json.dumps(upgradeable, indent=2, default=str)}"
            )
        )

        response = await llm.ainvoke([SYSTEM_PROMPT, user_message])
        raw_json = re.sub(r"```(?:json)?\n?", "", response.content).strip()
        estimates = json.loads(raw_json)

        logger.info(f"--> [UpgradeAdvisor] ROI Calculator done. {len(estimates)} recommendations.")
        return {"roiEstimates": estimates, "validationIssues": issues}

    except Exception as exc:
        logger.error(f"[UpgradeAdvisor] ROI Calculator Error: {exc}")
        return _mock_roi_estimates(upgradeable, [*issues, f"roi_calculator:error:{exc}"])


def _summarise_bills(bills: list[dict]) -> str:
    if not bills:
        return "No bill history provided."
    total_units = sum(float(b.get("units", 0)) for b in bills if b.get("units"))
    total_amount = sum(float(b.get("amount", 0)) for b in bills if b.get("amount"))
    avg_monthly = round(total_amount / len(bills), 2) if bills else 0
    return (
        f"{len(bills)} bills, avg monthly ₹{avg_monthly}, "
        f"total {total_units:.0f} kWh"
    )


def _mock_roi_estimates(profiles: list[dict], issues: list[str]) -> dict:
    estimates = []
    for i, p in enumerate(profiles[:3]):
        estimates.append({
            "rank": i + 1,
            "applianceId": p.get("applianceId"),
            "title": p.get("title"),
            "currentStarRating": p.get("currentStarRating", "Unknown"),
            "recommendedStarRating": "5",
            "upgradeCapexInr": p.get("upgradeCapexInr", 0),
            "monthlySavingsInr": p.get("monthlySavingsInr", 0),
            "annualSavingsInr": p.get("annualSavingsInr", 0),
            "paybackMonths": p.get("paybackMonths"),
            "headline": f"Upgrade your {p.get('title', 'appliance')} to BEE 5-Star",
            "rationale": (
                f"Upgrading saves ₹{p.get('annualSavingsInr', 0):.0f}/yr "
                f"with ~{p.get('paybackMonths', '?')} month payback."
            ),
            "urgency": "high" if i == 0 else "medium",
        })
    return {"roiEstimates": estimates, "validationIssues": issues}
