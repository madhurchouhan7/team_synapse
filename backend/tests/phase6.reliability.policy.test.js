const {
  invokeWithPolicy,
} = require("../src/agents/efficiency_plan/shared/reliabilityPolicy");

describe("phase6 reliability policy", () => {
  it("returns result without degradation when operation succeeds", async () => {
    const out = await invokeWithPolicy({
      label: "ok-op",
      operation: async () => "ok",
      fallbackValue: "fallback",
      retries: 1,
      timeoutMs: 50,
    });

    expect(out.degraded).toBe(false);
    expect(out.result).toBe("ok");
    expect(out.attempts).toBe(1);
  });

  it("uses fallback after retries are exhausted", async () => {
    const out = await invokeWithPolicy({
      label: "fail-op",
      operation: async () => {
        throw new Error("boom");
      },
      fallbackValue: "fallback",
      retries: 1,
      timeoutMs: 50,
    });

    expect(out.degraded).toBe(true);
    expect(out.result).toBe("fallback");
    expect(out.attempts).toBe(2);
  });
});
