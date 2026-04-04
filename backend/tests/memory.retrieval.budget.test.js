const {
  composeAgentContext,
} = require("../src/agents/efficiency_plan/shared/retrievalPlanner");

describe("memory retrieval budget", () => {
  it("enforces hard token budget", () => {
    const recent = Array.from({ length: 12 }).map((_, i) => ({
      id: `r-${i}`,
      text: "recent event text ".repeat(10),
    }));
    const historical = Array.from({ length: 20 }).map((_, i) => ({
      id: `h-${i}`,
      text: "historical long context ".repeat(20),
    }));

    const result = composeAgentContext({
      recentEvents: recent,
      historicalEvents: historical,
      query: "historical",
      tokenBudget: 100,
    });

    expect(result.tokenUsage).toBeLessThanOrEqual(100);
    expect(result.contextEvents.length).toBeGreaterThan(0);
  });

  it("falls back to recent-only when historical has no useful match", () => {
    const recent = [{ id: "r-1", text: "recent useful" }];
    const historical = [{ id: "h-1", text: "zzzzzzzz" }];

    const result = composeAgentContext({
      recentEvents: recent,
      historicalEvents: historical,
      query: "query-that-wont-match",
      tokenBudget: 100,
    });

    expect(result.usedFallback).toBe(true);
    expect(result.contextEvents[0].id).toBe("r-1");
  });
});
