jest.mock("../src/agents/efficiency_plan/copywriter.node", () => ({
  runCopywriter: jest.fn(async () => ({
    finalPlan: {
      planType: "efficiency",
      title: "Bad Plan",
      status: "draft",
      summary: "intentionally incomplete",
      keyActions: [],
    },
  })),
}));

const {
  collaborativePlanApp,
} = require("../src/agents/efficiency_plan/collaborative.index");
const memoryStore = require("../src/agents/efficiency_plan/shared/memoryStore.redis");

describe("phase4 challenge routing", () => {
  beforeEach(() => {
    memoryStore.__resetForTests();
  });

  it("runs bounded revision when cross-agent challenge is detected", async () => {
    const out = await collaborativePlanApp.invoke({
      userData: {
        appliances: [{ name: "AC", runtimeHours: 10 }],
      },
      weatherContext: "humid",
      memoryMeta: {
        tenantId: "tenant-1",
        userId: "user-1",
        threadId: "thread-1",
        runId: "run-1",
        requestId: "req-1",
        query: "optimize runtime",
      },
    });

    expect(out.revisionCount).toBeGreaterThan(0);
    expect(Array.isArray(out.finalPlan.keyActions)).toBe(true);
    expect(out.finalPlan.keyActions.length).toBeGreaterThan(0);
  });
});