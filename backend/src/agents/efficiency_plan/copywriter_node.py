"""
Copywriter Node (Powered by Gemini Flash).
Converted from copywriter.node.js — identical logic.
"""

import json
import os
import re
from typing import Any

from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.messages import HumanMessage

from .copywriter_prompt import get_copywriter_prompt
from .shared.phase4_contracts import normalize_strategies

# Initialize LangChain Gemini Client
llm = ChatGoogleGenerativeAI(
    model="gemini-2.5-flash",
    google_api_key=os.environ.get("GEMINI_API_KEY", "dummy"),
    temperature=0.4,
)


async def run_copywriter(state: dict[str, Any]) -> dict[str, Any]:
    """Synthesize analyst + strategist outputs into the final Flutter-ready JSON plan."""
    print("--> [Node] Copywriter Executing")

    try:
        normalized_strategies = normalize_strategies(
            state.get("strategies", []),
            state.get("anomalies", []),
        )
        system_message = get_copywriter_prompt()

        # Construct the prompt context
        context_string = (
            f"\nCurrent Weather Context: {state.get('weatherContext', 'Unknown')}\n"
            f"User Provided Data: {json.dumps(state.get('userData', {}), indent=2, default=str)}\n"
            f"Anomalies Detected (Analyst): {json.dumps(state.get('anomalies', []), indent=2, default=str)}\n"
            f"Strategies Generated (Strategist): {json.dumps(state.get('strategies', []), indent=2, default=str)}\n"
        )
        user_message = HumanMessage(content=context_string)

        if os.environ.get("GEMINI_API_KEY"):
            response = await llm.ainvoke([system_message, user_message])

            # Basic JSON extraction and sanitization
            raw_json_str = response.content
            if raw_json_str.startswith("```json"):
                raw_json_str = re.sub(r"```json\n?", "", raw_json_str)
                raw_json_str = re.sub(r"```\n?", "", raw_json_str)
            elif raw_json_str.startswith("```"):
                raw_json_str = re.sub(r"```\n?", "", raw_json_str)

            parsed_final_plan = json.loads(raw_json_str.strip())
            print("--> [Node] Copywriter completed successfully.")

            return {"finalPlan": parsed_final_plan}
        else:
            print("--> [Node] Copywriter using mock fallback (no GEMINI_API_KEY found).")
            return {
                "finalPlan": {
                    "planType": "efficiency",
                    "title": "Your Custom Energy Saving Plan",
                    "status": "draft",
                    "summary": (
                        "Hello! We noticed a few areas where you can save "
                        "significantly on your energy bill this month."
                    ),
                    "estimatedCurrentMonthlyCost": 2000,
                    "estimatedSavingsIfFollowed": {
                        "units": 50,
                        "rupees": 450,
                        "percentage": 22,
                    },
                    "efficiencyScore": 78,
                    "keyActions": [
                        {
                            "priority": "high",
                            "appliance": "Appliance",
                            "action": s.get("actionSummary", "Follow this action"),
                            "impact": s.get("fullDescription", "Save money effortlessly"),
                            "estimatedSaving": str(s.get("projectedSavings", "0")),
                        }
                        for s in normalized_strategies
                    ],
                    "slabAlert": {
                        "isInDangerZone": False,
                        "currentSlab": "Generic",
                        "warning": "",
                    },
                    "quickWins": ["Turn off lights", "Use natural ventilation"],
                    "monthlyTip": "Keep your AC filters clean for peak summer performance.",
                }
            }

    except Exception as error:
        print(f"Copywriter Node Error: {error}")
        normalized_strategies = normalize_strategies(
            state.get("strategies", []),
            state.get("anomalies", []),
        )
        fallback_rupees = sum(
            float(item.get("projectedSavings", 0)) for item in normalized_strategies
        )
        # Fail gracefully
        return {
            "finalPlan": {
                "planType": "efficiency",
                "title": "Your Custom Energy Saving Plan (Fallback)",
                "status": "draft",
                "summary": (
                    "Hello! We noticed a few areas where you can save significantly "
                    "on your energy bill this month. (Generated via fallback due to "
                    "API limits)."
                ),
                "estimatedCurrentMonthlyCost": 2000,
                "estimatedSavingsIfFollowed": {
                    "units": 50,
                    "rupees": max(450, fallback_rupees),
                    "percentage": 22,
                },
                "efficiencyScore": 78,
                "keyActions": [
                    {
                        "priority": "high" if i == 0 else "medium",
                        "appliance": "General Household",
                        "action": s["actionSummary"],
                        "impact": s["fullDescription"],
                        "estimatedSaving": str(s.get("projectedSavings", 0)),
                    }
                    for i, s in enumerate(normalized_strategies)
                ],
                "slabAlert": {
                    "isInDangerZone": False,
                    "currentSlab": "Generic",
                    "warning": "",
                },
                "quickWins": ["Turn off lights", "Use natural ventilation"],
                "monthlyTip": "Keep your AC filters clean for peak performance.",
            }
        }
