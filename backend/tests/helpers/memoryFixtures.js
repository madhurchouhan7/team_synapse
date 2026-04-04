const validIdentity = {
  tenantId: "tenant-1",
  userId: "user-1",
  threadId: "thread-1",
};

const validProvenanceEvent = {
  ...validIdentity,
  eventType: "agent_turn",
  agentId: "analyst",
  timestamp: "2026-03-23T00:00:00.000Z",
  sourceType: "llm",
  evidenceRefs: [{ id: "bill:123", type: "bill" }],
  revisionId: "rev-001",
  confidenceScore: 0.9,
  requestId: "req-1",
  runId: "run-1",
  payload: {
    message: "sample",
    token: "secret-token",
  },
};

const lowConfidenceNoEvidenceEvent = {
  ...validIdentity,
  eventType: "agent_turn",
  agentId: "strategist",
  timestamp: "2026-03-23T00:00:00.000Z",
  sourceType: "heuristic",
  evidenceRefs: [],
  noEvidenceReason: "heuristic estimate",
  revisionId: "rev-002",
  confidenceScore: 0.35,
  requestId: "req-2",
  runId: "run-2",
};

module.exports = {
  validIdentity,
  validProvenanceEvent,
  lowConfidenceNoEvidenceEvent,
};
