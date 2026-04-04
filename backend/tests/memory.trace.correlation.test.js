const {
  buildPlanResponseEnvelope,
} = require("../src/agents/efficiency_plan/orchestrators/responseEnvelope");
const loggingMiddleware = require("../src/middleware/logging.middleware");

describe("memory trace correlation", () => {
  it("includes memoryTrace in response metadata", () => {
    const out = buildPlanResponseEnvelope({
      finalPlan: {},
      requestedMode: "collaborative",
      executionPath: "collaborative",
      requestId: "req-1",
      runId: "run-1",
      threadId: "thread-1",
    });

    expect(out.metadata.memoryTrace).toEqual({
      requestId: "req-1",
      runId: "run-1",
      threadId: "thread-1",
    });
  });

  it("emits structured memory logs with trace fields", () => {
    const spy = jest.spyOn(console, "log").mockImplementation(() => {});

    loggingMiddleware.logMemoryEvent({
      eventType: "memory_fallback",
      scope: "tenant:user:thread",
      revisionId: "rev-1",
      requestId: "req-1",
      runId: "run-1",
      threadId: "thread-1",
      tokenBudgetUsed: 123,
      usedFallback: true,
    });

    expect(spy).toHaveBeenCalled();
    const serialized = JSON.stringify(spy.mock.calls[0]);
    expect(serialized).toContain("run-1");
    expect(serialized).toContain("thread-1");

    spy.mockRestore();
  });
});
