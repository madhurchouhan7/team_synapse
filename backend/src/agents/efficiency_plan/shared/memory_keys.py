"""
Memory identity key helpers.
Converted from shared/memoryKeys.js — identical logic.
"""

from ..exceptions import ApiError


def assert_memory_identity(ctx: dict | None = None) -> dict:
    """Validate and return trimmed tenantId, userId, threadId."""
    ctx = ctx or {}
    tenant_id = str(ctx.get("tenantId", "")).strip()
    user_id = str(ctx.get("userId", "")).strip()
    thread_id = str(ctx.get("threadId", "")).strip()

    if not tenant_id or not user_id or not thread_id:
        raise ApiError(
            400,
            "Missing required memory identity keys: tenantId, userId, threadId",
        )

    return {"tenantId": tenant_id, "userId": user_id, "threadId": thread_id}


def build_thread_scope(ctx: dict | None = None) -> str:
    identity = assert_memory_identity(ctx)
    return f"{identity['tenantId']}:{identity['userId']}:{identity['threadId']}"


def build_memory_keys(ctx: dict | None = None) -> dict:
    scope = build_thread_scope(ctx)
    return {
        "scope": scope,
        "eventsKey": f"memory:{scope}:events",
        "archiveKey": f"memory:{scope}:archive",
    }
