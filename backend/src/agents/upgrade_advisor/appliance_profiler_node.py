"""
Appliance Profiler Node — Node 1 of Upgrade Advisor workflow.

Enriches each user appliance with:
- Estimated wattage from the BEE benchmark (if not stored)
- Star-rating gap from BEE 5-star standard
- Monthly kWh and ₹ cost based on usage hours & bill tariff rate
- Upgrade feasibility flag

No LLM needed — pure deterministic computation.
"""

import logging
from typing import Any

logger = logging.getLogger("wattwise.agents.upgrade_advisor.appliance_profiler")

# ── BEE Star-Rating Wattage Benchmarks (Watts) ────────────────────────
# Format: { category_key: { star_rating: wattage } }
# For each star jump, wattage drops ~10–20% (BEE standard)
BEE_WATTAGE: dict[str, dict[str, float]] = {
    "Air Conditioner (1.5 Ton)": {
        "1": 2000, "2": 1800, "3": 1600, "4": 1400, "5": 1200,
        "BEE 1 Star": 2000, "BEE 2 Star": 1800, "BEE 3 Star": 1600,
        "BEE 4 Star": 1400, "BEE 5 Star": 1200,
    },
    "Air Conditioner (1 Ton)": {
        "1": 1400, "2": 1200, "3": 1050, "4": 950, "5": 800,
        "BEE 1 Star": 1400, "BEE 2 Star": 1200, "BEE 3 Star": 1050,
        "BEE 4 Star": 950, "BEE 5 Star": 800,
    },
    "Refrigerator (Double Door)": {
        "1": 350, "2": 280, "3": 220, "4": 180, "5": 150,
        "BEE 1 Star": 350, "BEE 2 Star": 280, "BEE 3 Star": 220,
        "BEE 4 Star": 180, "BEE 5 Star": 150,
    },
    "Refrigerator (Single Door)": {
        "1": 200, "2": 160, "3": 140, "4": 120, "5": 100,
        "BEE 1 Star": 200, "BEE 2 Star": 160, "BEE 3 Star": 140,
        "BEE 4 Star": 120, "BEE 5 Star": 100,
    },
    "Washing Machine": {
        "1": 700, "2": 600, "3": 500, "4": 400, "5": 350,
        "BEE 1 Star": 700, "BEE 2 Star": 600, "BEE 3 Star": 500,
        "BEE 4 Star": 400, "BEE 5 Star": 350,
    },
    "Ceiling Fan": {
        "1": 75, "2": 65, "3": 55, "4": 45, "5": 35,
        "BEE 1 Star": 75, "BEE 2 Star": 65, "BEE 3 Star": 55,
        "BEE 4 Star": 45, "BEE 5 Star": 35,
    },
    "Television (LED)": {
        "1": 150, "2": 120, "3": 100, "4": 80, "5": 60,
        "BEE 1 Star": 150, "BEE 2 Star": 120, "BEE 3 Star": 100,
        "BEE 4 Star": 80, "BEE 5 Star": 60,
    },
    "Geyser (Water Heater)": {
        "1": 2500, "2": 2200, "3": 2000, "4": 1800, "5": 1600,
        "BEE 1 Star": 2500, "BEE 2 Star": 2200, "BEE 3 Star": 2000,
        "BEE 4 Star": 1800, "BEE 5 Star": 1600,
    },
}

# Approximate market upgrade cost (₹) for each category
UPGRADE_COST_INR: dict[str, float] = {
    "Air Conditioner (1.5 Ton)": 38000,
    "Air Conditioner (1 Ton)": 32000,
    "Refrigerator (Double Door)": 28000,
    "Refrigerator (Single Door)": 16000,
    "Washing Machine": 20000,
    "Ceiling Fan": 2000,
    "Television (LED)": 18000,
    "Geyser (Water Heater)": 8000,
}

STAR_ORDER = ["1", "BEE 1 Star", "2", "BEE 2 Star", "3", "BEE 3 Star",
              "4", "BEE 4 Star", "5", "BEE 5 Star"]
STAR_NUMERIC = {
    "1": 1, "BEE 1 Star": 1, "2": 2, "BEE 2 Star": 2,
    "3": 3, "BEE 3 Star": 3, "4": 4, "BEE 4 Star": 4,
    "5": 5, "BEE 5 Star": 5,
}


def _compute_tariff_rate(bills: list[dict]) -> float:
    """Compute average ₹/kWh from recent bill history."""
    valid = [
        (float(b["amount"]), float(b["units"]))
        for b in bills
        if b.get("amount") and b.get("units") and float(b.get("units", 0)) > 0
    ]
    if not valid:
        return 7.0  # Default Indian residential tariff fallback
    total_amount = sum(a for a, _ in valid)
    total_units = sum(u for _, u in valid)
    return round(total_amount / total_units, 3)


async def run_appliance_profiler(state: dict[str, Any]) -> dict[str, Any]:
    """Enrich each appliance with star gap, monthly cost, and upgrade metadata."""
    logger.info("--> [UpgradeAdvisor] Appliance Profiler Node Executing")

    appliances = state.get("appliances") or []
    bills = state.get("bills") or []
    issues: list[str] = []

    if not appliances:
        issues.append("profiler:no_appliances_provided")
        return {"applianceProfiles": [], "validationIssues": issues}

    tariff_rate = _compute_tariff_rate(bills)
    profiles: list[dict[str, Any]] = []

    for appliance in appliances:
        title = appliance.get("title", "Unknown")
        star = str(appliance.get("starRating") or "")
        wattage = appliance.get("wattage")
        usage_hours = float(appliance.get("usageHoursPerDay") or 0)
        count = int(appliance.get("count") or 1)

        # Lookup BEE benchmarks for this appliance type
        bee_data = BEE_WATTAGE.get(title, {})

        current_star_num = STAR_NUMERIC.get(star, 0)
        best_star_num = 5

        # Effective wattage: use stored or look up from BEE
        current_wattage = float(wattage or 0)
        if not current_wattage and bee_data and star:
            current_wattage = bee_data.get(star, 0)

        best_wattage = float(bee_data.get("5", bee_data.get("BEE 5 Star", current_wattage)))

        # Monthly savings from upgrading to BEE 5-star
        monthly_kwh_current = (current_wattage * usage_hours * count * 30) / 1000
        monthly_kwh_best = (best_wattage * usage_hours * count * 30) / 1000
        monthly_savings_kwh = max(0.0, monthly_kwh_current - monthly_kwh_best)
        monthly_savings_inr = round(monthly_savings_kwh * tariff_rate, 2)
        annual_savings_inr = round(monthly_savings_inr * 12, 2)

        upgrade_cost = UPGRADE_COST_INR.get(title, 0)
        payback_months = (
            round(upgrade_cost / monthly_savings_inr, 1)
            if monthly_savings_inr > 0
            else None
        )

        star_gap = best_star_num - current_star_num
        is_upgradeable = star_gap > 0 and upgrade_cost > 0 and usage_hours > 0

        profiles.append({
            "applianceId": appliance.get("applianceId"),
            "title": title,
            "category": appliance.get("category"),
            "currentStarRating": star or "Unknown",
            "currentStarNum": current_star_num,
            "bestAvailableStarNum": best_star_num,
            "starGap": star_gap,
            "currentWattage": current_wattage,
            "optimalWattage": best_wattage,
            "usageHoursPerDay": usage_hours,
            "count": count,
            "monthlyCostCurrent": round(monthly_kwh_current * tariff_rate, 2),
            "monthlyCostOptimal": round(monthly_kwh_best * tariff_rate, 2),
            "monthlyKwhSavings": round(monthly_savings_kwh, 2),
            "monthlySavingsInr": monthly_savings_inr,
            "annualSavingsInr": annual_savings_inr,
            "upgradeCapexInr": upgrade_cost,
            "paybackMonths": payback_months,
            "isUpgradeable": is_upgradeable,
            "tariffRateUsed": tariff_rate,
        })

    logger.info(
        f"--> [UpgradeAdvisor] Profiler done. {len(profiles)} profiles, "
        f"tariff={tariff_rate} ₹/kWh"
    )

    return {"applianceProfiles": profiles, "validationIssues": issues}
