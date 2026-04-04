jest.mock("../src/agents/efficiency_plan/strategist.node", () => ({
  runStrategist: jest.fn(async () => {
    throw new Error("strategist-down");
  }),
}));

const {
  collaborativePlanApp,
} = require("../src/agents/efficiency_plan/collaborative.index");
const memoryStore = require("../src/agents/efficiency_plan/shared/memoryStore.redis");

describe("phase6 degradation integration", () => {
  beforeEach(() => {
    memoryStore.__resetForTests();
  });

  it("captures degraded strategist path and still returns a final plan", async () => {
    const out = await collaborativePlanApp.invoke({
      userData: {
        appliances: [{ name: "AC", runtimeHours: 11 }],
      },
      weatherContext: "hot",
      memoryMeta: {
        tenantId: "tenant-1",
        userId: "user-1",
        threadId: "thread-1",
        runId: "run-1",
        requestId: "req-1",
        query: "degraded path",
      },
    });

    expect(out.finalPlan).toBeTruthy();
    expect(Array.isArray(out.degradationEvents)).toBe(true);
    expect(out.degradationEvents.length).toBeGreaterThan(0);
    expect(out.degradationEvents[0].agent).toBe("strategist");
    expect(
      out.validationIssues.some((item) =>
        item.startsWith("ops:degraded:strategist"),
      ),
    ).toBe(true);
  });
});
