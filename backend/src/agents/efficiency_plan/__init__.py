# src/agents/efficiency_plan/__init__.py
"""WattWise Efficiency Plan Multi-Agent Workflow (Python/FastAPI)"""


def get_efficiency_plan_app():
    """Lazy import to avoid circular import issues when used as a library."""
    from .index import efficiency_plan_app
    return efficiency_plan_app


def get_collaborative_plan_app():
    """Lazy import to avoid circular import issues when used as a library."""
    from .collaborative_index import collaborative_plan_app
    return collaborative_plan_app
