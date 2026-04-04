jest.mock("../src/agents/efficiency_plan/shared/debateConsensus", () => ({
  runDebateAndConsensus: jest.fn(() => ({
    finalQualityScore: 61,
    debateRounds: 2,
    gatePassed: false,
    minQualityScore: 85,
    consensusLog: [
      {
        round: 1,
        qualityScore: 58,
        unresolvedIssues: 3,
        unresolvedChallenges: 2,
        votes: [
          {
            role: "analyst",
            confidence: 58,
            stance: "revise",
            rationale: "round-1:issues=3",
          },
        ],
      },
      {
        round: 2,
        qualityScore: 61,
        unresolvedIssues: 2,
        unresolvedChallenges: 1,
        votes: [
          {
            role: "strategist",
            confidence: 61,
            stance: "revise",
            rationale: "round-2:issues=2",
          },
        ],
      },
    ],
  })),
}));

const {
  collaborativePlanApp,
} = require("../src/agents/efficiency_plan/collaborative.index");
const memoryStore = require("../src/agents/efficiency_plan/shared/memoryStore.redis");

describe("phase5 safe fallback", () => {
  beforeEach(() => {
    memoryStore.__resetForTests();
  });

  it("activates safe fallback when quality gate remains unresolved", async () => {
    const out = await collaborativePlanApp.invoke({
      userData: {
        appliances: [{ name: "AC", runtimeHours: 14 }],
      },
      weatherContext: "humid",
      memoryMeta: {
        tenantId: "tenant-1",
        userId: "user-1",
        threadId: "thread-1",
        runId: "run-1",
        requestId: "req-1",
        query: "reduce peak load",
      },
    });

    expect(out.qualityGate).toEqual({ minScore: 85, passed: false });
    expect(out.safeFallbackActivated).toBe(true);
    expect(out.finalPlan.status).toBe("safe_fallback");
    expect(out.finalPlan.summary).toContain("Safe fallback activated");
    expect(Array.isArray(out.consensusLog)).toBe(true);
    expect(out.consensusLog.length).toBeGreaterThan(0);
  });
});
