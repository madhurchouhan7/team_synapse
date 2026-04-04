"""
WattWise Upgrade Advisor LangGraph Workflow Definition.

Pipeline:  Appliance Profiler → ROI Calculator → Recommendation Formatter
- Appliance Profiler: Deterministic BEE star-gap & ₹ cost computation
- ROI Calculator: Gemini-powered, weather-aware upgrade priority ranking
- Recommendation Formatter: Flutter-ready JSON assembly
"""

from langgraph.graph import StateGraph, START, END

from .state import UpgradeAdvisorState
from .appliance_profiler_node import run_appliance_profiler
from .roi_calculator_node import run_roi_calculator
from .recommendation_formatter_node import run_recommendation_formatter

# 1. Initialise graph
workflow = StateGraph(UpgradeAdvisorState)

# 2. Add nodes
workflow.add_node("ApplianceProfiler", run_appliance_profiler)
workflow.add_node("RoiCalculator", run_roi_calculator)
workflow.add_node("RecommendationFormatter", run_recommendation_formatter)

# 3. Define sequential edges
workflow.add_edge(START, "ApplianceProfiler")
workflow.add_edge("ApplianceProfiler", "RoiCalculator")
workflow.add_edge("RoiCalculator", "RecommendationFormatter")
workflow.add_edge("RecommendationFormatter", END)

# 4. Compile
upgrade_advisor_app = workflow.compile()
