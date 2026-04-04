"""
WattWise Efficiency Plan LangGraph Definition.
Compiles the Analyst, Strategist, and Copywriter nodes into a single workflow.
Converted from index.js — identical graph structure.
"""

from langgraph.graph import StateGraph, START, END

from .state import PlanState
from .analyst_node import run_analyst
from .strategist_node import run_strategist
from .copywriter_node import run_copywriter

# 1. Initialize the graph with our state schema
workflow = StateGraph(PlanState)

# 2. Add nodes
workflow.add_node("Analyst", run_analyst)
workflow.add_node("Strategist", run_strategist)
workflow.add_node("Copywriter", run_copywriter)

# 3. Define structured edges to enforce the sequential assembly line
workflow.add_edge(START, "Analyst")
workflow.add_edge("Analyst", "Strategist")
workflow.add_edge("Strategist", "Copywriter")
workflow.add_edge("Copywriter", END)

# 4. Compile the application
efficiency_plan_app = workflow.compile()
