const express = require("express");
const request = require("supertest");

const mockOrchestrators = {
  legacyInvoke: jest.fn(),
  collaborativeInvoke: jest.fn(),
};

jest.mock("../src/middleware/authMiddleware", () => (req, _res, next) => {
  req.user = { id: "test-user", tenantId: "tenant-test" };
  next();
});

jest.mock("../src/agents/efficiency_plan/index", () => ({
  efficiencyPlanApp: {
    invoke: (...args) => mockOrchestrators.legacyInvoke(...args),
  },
}));

jest.mock("../src/agents/efficiency_plan/collaborative.index", () => ({
  collaborativePlanApp: {
    invoke: (...args) => mockOrchestrators.collaborativeInvoke(...args),
  },
}));

const aiRoutes = require("../src/routes/ai.routes");
const {
  errorHandler,
  notFoundHandler,
} = require("../src/middleware/errorHandler");
const {
  collaborativeSuccessStub,
  defaultFinalPlan,
} = require("./helpers/mockOrchestrators");

function createTestApp() {
  const app = express();
  app.use((req, _res, next) => {
    req.id = "req-test-phase5-fallback";
    next();
  });
  app.use(express.json());
  app.use("/api/v1/ai", aiRoutes);
  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
}

describe("AI phase5 safe fallback contract", () => {
  beforeEach(() => {
    process.env.OPENWEATHER_API_KEY = "";
    process.env.NODE_ENV = "development";

    const safeFallbackPlan = {
      ...defaultFinalPlan("Safe Fallback Plan"),
      status: "safe_fallback",
      summary:
        "Safe fallback activated after unresolved debate. Review and refine this plan before publish.",
    };

    mockOrchestrators.collaborativeInvoke = collaborativeSuccessStub({
      finalPlan: safeFallbackPlan,
      qualityScore: 61,
      debateRounds: 2,
      qualityGate: { minScore: 85, passed: false },
      consensusLog: [
        {
          round: 1,
          qualityScore: 58,
          unresolvedIssues: 3,
          unresolvedChallenges: 2,
          votes: [
            {
              role: "analyst",
              stance: "revise",
              confidence: 58,
              rationale: "round-1:issues=3",
            },
          ],
        },
      ],
      safeFallbackActivated: true,
      consensusDecision: {
        stance: "revise",
        tieBreakApplied: false,
        tieBreakRule: null,
      },
      unresolvedRoute: "safe_fallback",
    }).invoke;
  });

  it("returns safe fallback plan and phase5 decision metadata", async () => {
    const app = createTestApp();

    const res = await request(app)
      .post("/api/v1/ai/generate-plan")
      .set("Authorization", "Bearer test-token")
      .set("x-thread-id", "thread-phase5")
      .send({ user: { location: "India" }, appliances: [] });

    expect(res.status).toBe(200);
    expect(res.body.data.finalPlan.status).toBe("safe_fallback");
    expect(res.body.data.metadata.phase5).toEqual(
      expect.objectContaining({
        qualityGate: { minScore: 85, passed: false },
        safeFallbackActivated: true,
        unresolvedRoute: "safe_fallback",
        consensusDecision: {
          stance: "revise",
          tieBreakApplied: false,
          tieBreakRule: null,
        },
      }),
    );
  });
});
