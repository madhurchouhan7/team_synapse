"""
Data Analyst Node (Powered by OpenRouter / DeepSeek-R1 fallback).
Converted from analyst.node.js — identical logic.
"""

import json
import os
import re
from typing import Any

from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage

from .analyst_prompt import get_analyst_prompt

# Initialize LangChain OpenAI client targeting OpenRouter API
llm = ChatOpenAI(
    model="openai/gpt-4o-mini",
    api_key=os.environ.get("OPENROUTER_API_KEY", "dummy"),
    base_url="https://openrouter.ai/api/v1",
    temperature=0.1,
)


async def run_analyst(state: dict[str, Any]) -> dict[str, Any]:
    """Analyse user data against physics benchmarks and detect anomalies."""
    print("--> [Node] Data Analyst Executing")

    try:
        if not state.get("userData"):
            print("No userData found. Skipping anomaly detection.")
            return {"anomalies": []}

        system_message = get_analyst_prompt()
        context_string = (
            f"Analyze this user data:\n{json.dumps(state.get('userData', {}), indent=2, default=str)}\n\n"
            f"Past Memory Context (from Vector DB):\n{json.dumps(state.get('memoryContext', []), indent=2, default=str)}\n\n"
            f"Current Weather Context: {state.get('weatherContext', 'Unknown/Average Weather')}\n"
        )
        user_message = HumanMessage(content=context_string)

        if os.environ.get("OPENROUTER_API_KEY"):
            response = await llm.ainvoke([system_message, user_message])

            # Robust JSON extraction — strip any markdown fencing
            raw_json_str = re.sub(r"```(?:json)?\n?", "", response.content).strip()

            parsed_anomalies = json.loads(raw_json_str)
            print(f"--> [Node] Analyst completed. Found {len(parsed_anomalies)} anomalies.")

            return {"anomalies": parsed_anomalies}
        else:
            print("--> [Node] Analyst using mock fallback (no OPENROUTER_API_KEY found.)")  # noqa: E501
            return {
                "anomalies": [
                    {
                        "id": "mock_anomaly",
                        "item": "Washing Machine",
                        "description": "Washing machine used 8 hours exceeding 2h benchmark.",
                        "rupeeCostImpact": 450,
                    }
                ]
            }

    except Exception as error:
        print(f"Analyst Node Error: {error}")
        # Fail gracefully with mock anomalies
        return {
            "anomalies": [
                {
                    "id": "mock_error_anomaly",
                    "item": "Air Conditioner (1.5 Ton)",
                    "description": "Used for 18 hours, exceeding 12h benchmark.",
                    "rupeeCostImpact": 1250,
                }
            ]
        }
