"""
State schema for the Upgrade Advisor multi-agent workflow.
"""

from typing import Any, Optional
from typing_extensions import TypedDict


class UpgradeAdvisorState(TypedDict, total=False):
    """State passed between LangGraph nodes in the Upgrade Advisor graph."""

    # Input context
    appliances: list[dict[str, Any]]        # User's current appliances from MongoDB
    bills: list[dict[str, Any]]             # Past 3–12 months of bill data
    weatherContext: str                     # Real-time weather from OpenWeather

    # Intermediate
    applianceProfiles: list[dict[str, Any]] # Enriched appliance profiles with star-rating gaps
    roiEstimates: list[dict[str, Any]]      # Per-appliance ROI calculations

    # Final output
    upgradeRecommendations: Optional[dict[str, Any]]  # Flutter-ready recommendations JSON
    validationIssues: list[str]
