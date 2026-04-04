"""
Memory event validation schemas using Pydantic.
Converted from shared/memorySchema.js (Zod) — identical validation logic.
"""

from typing import Any, Optional
from pydantic import BaseModel, Field, model_validator


class MemoryIdentity(BaseModel):
    tenantId: str = Field(..., min_length=1)
    userId: str = Field(..., min_length=1)
    threadId: str = Field(..., min_length=1)


class EvidenceRef(BaseModel):
    id: str = Field(..., min_length=1)
    type: Optional[str] = None


class MemoryEvent(BaseModel):
    tenantId: str = Field(..., min_length=1)
    userId: str = Field(..., min_length=1)
    threadId: str = Field(..., min_length=1)
    eventType: str = Field(default="agent_turn", min_length=1)
    agentId: str = Field(..., min_length=1)
    timestamp: str = Field(..., min_length=1)
    sourceType: str = Field(..., min_length=1)
    evidenceRefs: list[EvidenceRef] = Field(default_factory=list)
    noEvidenceReason: Optional[str] = None
    revisionId: str = Field(..., min_length=1)
    confidenceScore: float = Field(..., ge=0, le=1)
    requestId: Optional[str] = None
    runId: Optional[str] = None
    payload: Optional[Any] = None

    @model_validator(mode="after")
    def check_evidence_rules(self):
        has_evidence = len(self.evidenceRefs) > 0

        if not has_evidence and self.confidenceScore > 0.49:
            raise ValueError(
                "evidenceRefs required when confidenceScore > 0.49"
            )

        if (
            not has_evidence
            and self.confidenceScore <= 0.49
            and not self.noEvidenceReason
        ):
            raise ValueError(
                "noEvidenceReason required when evidenceRefs is empty "
                "and confidenceScore <= 0.49"
            )

        return self


def validate_memory_event(input_data: dict) -> dict:
    """
    Validate a memory event dict.
    Returns {"success": True, "data": ...} or {"success": False, "error": ...}.
    """
    try:
        event = MemoryEvent(**input_data)
        return {"success": True, "data": event.model_dump()}
    except Exception as exc:
        return {"success": False, "error": exc}
