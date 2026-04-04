const {
  collaborativePlanApp,
} = require("../src/agents/efficiency_plan/collaborative.index");
const memoryStore = require("../src/agents/efficiency_plan/shared/memoryStore.redis");

describe("memory context continuity", () => {
  beforeEach(() => {
    memoryStore.__resetForTests();
  });

  it("carries prior turn artifacts into next collaborative turn context", async () => {
    const memoryMeta = {
      tenantId: "tenant-1",
      userId: "user-1",
      threadId: "thread-1",
      runId: "run-1",
      requestId: "req-1",
      query: "usage",
    };

    const first = await collaborativePlanApp.invoke({
      userData: { appliances: [{ name: "AC" }] },
      weatherContext: "hot",
      memoryMeta,
    });

    expect(first.memoryEventRefs).toHaveLength(1);

    const second = await collaborativePlanApp.invoke({
      userData: { appliances: [{ name: "Fan" }] },
      weatherContext: "humid",
      memoryMeta: {
        ...memoryMeta,
        runId: "run-2",
        requestId: "req-2",
        query: "collaborative",
      },
    });

    expect(second.memoryContext.length).toBeGreaterThan(0);
    expect(second.memoryEventRefs).toHaveLength(1);
  });

  it("rejects collaborative invoke when identity keys are missing", async () => {
    await expect(
      collaborativePlanApp.invoke({
        userData: {},
        memoryMeta: { userId: "user-only", threadId: "thread-only" },
      }),
    ).rejects.toMatchObject({ statusCode: 400 });
  });
});
