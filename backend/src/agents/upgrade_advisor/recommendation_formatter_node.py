"""
Recommendation Formatter Node — Node 3 (Final) of Upgrade Advisor workflow.

Pure deterministic node that assembles the ROI estimates and profiles
into the final Flutter-ready JSON response envelope.
"""

import logging
from datetime import datetime, timezone
from typing import Any

logger = logging.getLogger("wattwise.agents.upgrade_advisor.recommendation_formatter")


async def run_recommendation_formatter(state: dict[str, Any]) -> dict[str, Any]:
    """Assemble the final Flutter-ready upgrade recommendation payload."""
    logger.info("--> [UpgradeAdvisor] Recommendation Formatter Node Executing")

    roi_estimates = state.get("roiEstimates") or []
    profiles = state.get("applianceProfiles") or []
    issues = list(state.get("validationIssues") or [])

    # Aggregate totals across all recommended upgrades
    total_capex = sum(float(r.get("upgradeCapexInr", 0)) for r in roi_estimates)
    total_annual_savings = sum(float(r.get("annualSavingsInr", 0)) for r in roi_estimates)
    avg_payback = (
        round(total_capex / (total_annual_savings / 12), 1)
        if total_annual_savings > 0
        else None
    )

    # Non-upgradeable appliances listed for transparency
    non_upgradeable = [
        {
            "applianceId": p.get("applianceId"),
            "title": p.get("title"),
            "reason": (
                "Already at BEE 5-Star rating"
                if p.get("currentStarNum", 0) >= 5
                else "Low usage hours — upgrade ROI too long"
            ),
        }
        for p in profiles
        if not p.get("isUpgradeable")
    ]

    output: dict[str, Any] = {
        "planType": "upgrade",
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "summary": (
            f"We found {len(roi_estimates)} appliance upgrade(s) that can "
            f"save you ₹{total_annual_savings:.0f}/year. "
            f"Combined investment of ₹{total_capex:.0f} pays back in "
            f"{avg_payback} months."
            if roi_estimates
            else "Your appliances are already well-optimised. No high-ROI upgrades found."
        ),
        "topRecommendations": roi_estimates,
        "aggregateSavings": {
            "totalCapexInr": round(total_capex, 2),
            "totalAnnualSavingsInr": round(total_annual_savings, 2),
            "avgPaybackMonths": avg_payback,
        },
        "alreadyOptimised": non_upgradeable,
        "validationIssues": issues,
        "requiresReview": len(issues) > 0,
    }

    logger.info(
        f"--> [UpgradeAdvisor] Formatter done. "
        f"Recommendations={len(roi_estimates)}, totalSavings=₹{total_annual_savings:.0f}"
    )

    return {"upgradeRecommendations": output}
