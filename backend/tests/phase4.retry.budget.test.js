jest.mock("../src/agents/efficiency_plan/copywriter.node", () => ({
  runCopywriter: jest.fn(async () => ({
    finalPlan: {
      planType: "efficiency",
      title: "Invalid Plan",
      status: "draft",
      summary: "missing required keyActions",
      keyActions: [],
    },
  })),
}));

const {
  collaborativePlanApp,
} = require("../src/agents/efficiency_plan/collaborative.index");
const memoryStore = require("../src/agents/efficiency_plan/shared/memoryStore.redis");

describe("phase4 role retry budgets", () => {
  beforeEach(() => {
    memoryStore.__resetForTests();
  });

  it("increments copywriter retry budget when final plan fails validation", async () => {
    const out = await collaborativePlanApp.invoke({
      userData: {
        appliances: [{ name: "Geyser", runtimeHours: 6 }],
      },
      weatherContext: "warm",
      memoryMeta: {
        tenantId: "tenant-1",
        userId: "user-1",
        threadId: "thread-1",
        runId: "run-1",
        requestId: "req-1",
        query: "cut water heating usage",
      },
    });

    expect(out.roleRetryBudgets.copywriter).toBeGreaterThan(0);
    expect(out.revisionCount).toBeGreaterThan(0);
    expect(Array.isArray(out.finalPlan.keyActions)).toBe(true);
    expect(out.finalPlan.keyActions.length).toBeGreaterThan(0);
  });
});
