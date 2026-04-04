"""
Strategist Node (Powered by OpenRouter / Grok).
Converted from strategist.node.js — identical logic.
"""

import json
import os
import re
from typing import Any

from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage

from .strategist_prompt import get_strategist_prompt


def _build_default_strategies() -> list[dict]:
    return [
        {
            "id": "fallback_strategy_1",
            "actionSummary": "Optimize AC + fan combination",
            "fullDescription": (
                "Set AC to 24-25C and use fan circulation to reduce "
                "compressor duty cycles."
            ),
            "projectedSavings": 450,
        },
        {
            "id": "fallback_strategy_2",
            "actionSummary": "Shift washer and heater usage",
            "fullDescription": (
                "Run washing machine and water heater during off-peak "
                "periods when possible."
            ),
            "projectedSavings": 300,
        },
        {
            "id": "fallback_strategy_3",
            "actionSummary": "Eliminate standby consumption",
            "fullDescription": (
                "Turn off idle entertainment devices, chargers, and kitchen "
                "plug loads nightly."
            ),
            "projectedSavings": 220,
        },
        {
            "id": "fallback_strategy_4",
            "actionSummary": "Cap daily high-load runtime",
            "fullDescription": (
                "Reduce one major appliance runtime by 15-20 minutes each day."
            ),
            "projectedSavings": 180,
        },
    ]


# Initialize LangChain OpenAI client targeting OpenRouter API (Grok)
llm = ChatOpenAI(
    model="x-ai/grok-4.1-fast",
    api_key=os.environ.get("OPENROUTER_API_KEY", "dummy"),
    base_url="https://openrouter.ai/api/v1",
    temperature=0.2,
)


async def run_strategist(state: dict[str, Any]) -> dict[str, Any]:
    """Generate practical energy-saving strategies from anomalies and weather context."""
    print("--> [Node] Strategist Executing")

    try:
        system_message = get_strategist_prompt()

        # Construct the prompt context
        user_data = state.get("userData", {})
        appliances_data = (
            user_data.get("appliances", user_data)
            if isinstance(user_data, dict)
            else user_data
        )

        anomalies = state.get("anomalies", [])
        anomalies_str = (
            json.dumps(anomalies, indent=2, default=str)
            if anomalies
            else (
                "No severe physics anomalies detected. Generate proactive "
                "baseline savings strategies based on their appliances and "
                "weather context."
            )
        )

        context_string = (
            f"\nCurrent Weather Context: {state.get('weatherContext', 'Unknown/Average Weather')}\n\n"
            f"User Appliances/Data:\n{json.dumps(appliances_data, indent=2, default=str)}\n\n"
            f"Identified Anomalies from Analyst:\n{anomalies_str}\n"
        )
        user_message = HumanMessage(content=context_string)

        if os.environ.get("OPENROUTER_API_KEY"):
            response = await llm.ainvoke([system_message, user_message])

            # Basic JSON extraction and sanitization
            raw_json_str = response.content
            if raw_json_str.startswith("```json"):
                raw_json_str = re.sub(r"```json\n?", "", raw_json_str)
                raw_json_str = re.sub(r"```\n?", "", raw_json_str)
            elif raw_json_str.startswith("```"):
                raw_json_str = re.sub(r"```\n?", "", raw_json_str)

            parsed_strategies = json.loads(raw_json_str.strip())
            print(
                f"--> [Node] Strategist completed. "
                f"Generated {len(parsed_strategies)} strategies."
            )

            return {"strategies": parsed_strategies}
        else:
            print("--> [Node] Strategist using mock fallback (no OPENROUTER_API_KEY found).")
            return {"strategies": _build_default_strategies()}

    except Exception as error:
        print(f"Strategist Node Error: {error}")
        # Fail gracefully with mock data
        return {"strategies": _build_default_strategies()}
