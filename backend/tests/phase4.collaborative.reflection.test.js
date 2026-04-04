const {
  collaborativePlanApp,
} = require("../src/agents/efficiency_plan/collaborative.index");
const memoryStore = require("../src/agents/efficiency_plan/shared/memoryStore.redis");

describe("phase4 collaborative reflection", () => {
  beforeEach(() => {
    memoryStore.__resetForTests();
  });

  it("returns reflection, validation, and challenge channels", async () => {
    const out = await collaborativePlanApp.invoke({
      userData: {
        appliances: [{ name: "AC", runtimeHours: 12 }],
      },
      weatherContext: "hot",
      memoryMeta: {
        tenantId: "tenant-1",
        userId: "user-1",
        threadId: "thread-1",
        runId: "run-1",
        requestId: "req-1",
        query: "reduce AC bill",
      },
    });

    expect(Array.isArray(out.agentReflections)).toBe(true);
    expect(out.agentReflections).toHaveLength(3);
    expect(Array.isArray(out.validationIssues)).toBe(true);
    expect(Array.isArray(out.crossAgentChallenges)).toBe(true);
    expect(Number.isFinite(out.revisionCount)).toBe(true);
    expect(Number.isFinite(out.qualityScore)).toBe(true);
    expect(Number.isFinite(out.debateRounds)).toBe(true);
    expect(Array.isArray(out.consensusLog)).toBe(true);
    expect(out.qualityGate).toEqual(
      expect.objectContaining({
        minScore: expect.any(Number),
        passed: expect.any(Boolean),
      }),
    );
    expect(out.roleRetryBudgets).toEqual(
      expect.objectContaining({
        analyst: expect.any(Number),
        strategist: expect.any(Number),
        copywriter: expect.any(Number),
        challengeRouting: expect.any(Number),
      }),
    );
    expect(out.finalPlan).toBeTruthy();
    expect(Array.isArray(out.finalPlan.keyActions)).toBe(true);
    expect(out.finalPlan.keyActions.length).toBeGreaterThan(0);
  });
});
