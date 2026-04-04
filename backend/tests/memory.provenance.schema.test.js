const {
  assertMemoryIdentity,
  buildThreadScope,
} = require("../src/agents/efficiency_plan/shared/memoryKeys");
const {
  validateMemoryEvent,
} = require("../src/agents/efficiency_plan/shared/memorySchema");
const {
  redactMemoryPayload,
} = require("../src/agents/efficiency_plan/shared/redaction");
const {
  validIdentity,
  validProvenanceEvent,
  lowConfidenceNoEvidenceEvent,
} = require("./helpers/memoryFixtures");

describe("memory identity + provenance contracts", () => {
  it("builds canonical thread scope", () => {
    const scope = buildThreadScope(validIdentity);
    expect(scope).toBe("tenant-1:user-1:thread-1");
  });

  it("rejects missing identity fields", () => {
    expect(() =>
      assertMemoryIdentity({ tenantId: "t1", userId: "u1" }),
    ).toThrow("Missing required memory identity keys");
  });

  it("accepts valid provenance event", () => {
    const result = validateMemoryEvent(validProvenanceEvent);
    expect(result.success).toBe(true);
  });

  it("rejects missing required provenance fields", () => {
    const bad = { ...validProvenanceEvent };
    delete bad.agentId;
    const result = validateMemoryEvent(bad);
    expect(result.success).toBe(false);
  });

  it("allows low confidence events without evidence when reason exists", () => {
    const result = validateMemoryEvent(lowConfidenceNoEvidenceEvent);
    expect(result.success).toBe(true);
  });

  it("redacts sensitive fields deterministically", () => {
    const payload = {
      token: "abc",
      nested: { password: "xyz" },
      items: [{ authorization: "bearer-123" }],
    };
    const once = redactMemoryPayload(payload);
    const twice = redactMemoryPayload(payload);

    expect(once.token).toMatch(/^\[TOKENIZED:/);
    expect(once.nested.password).toMatch(/^\[TOKENIZED:/);
    expect(once.items[0].authorization).toMatch(/^\[TOKENIZED:/);
    expect(once.token).toBe(twice.token);
  });
});
