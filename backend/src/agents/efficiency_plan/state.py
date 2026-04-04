"""
State Annotation for the WattWise Efficiency Plan Multi-Agent Workflow.
Converted from state.js — uses TypedDict for LangGraph Python.
"""

from typing import Any, Optional
from typing_extensions import TypedDict


class PlanState(TypedDict, total=False):
    """Schema for the state object passed between LangGraph nodes."""

    userData: Optional[dict[str, Any]]
    weatherContext: str
    anomalies: list[dict[str, Any]]
    strategies: list[dict[str, Any]]
    finalPlan: Optional[dict[str, Any]]
    memoryContext: list[dict[str, Any]]
    memoryEventRefs: list[str]
    agentReflections: list[dict[str, Any]]
    validationIssues: list[str]
    crossAgentChallenges: list[dict[str, Any]]
    revisionCount: int
    roleRetryBudgets: dict[str, int]
    consensusLog: list[dict[str, Any]]
    qualityGate: dict[str, Any]
    degradationEvents: list[dict[str, Any]]
