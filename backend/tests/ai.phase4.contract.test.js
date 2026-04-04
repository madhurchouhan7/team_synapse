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
    req.id = "req-test-phase4";
    next();
  });
  app.use(express.json());
  app.use("/api/v1/ai", aiRoutes);
  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
}

describe("AI phase4 response contract", () => {
  beforeEach(() => {
    process.env.OPENWEATHER_API_KEY = "";
    process.env.NODE_ENV = "development";
    mockOrchestrators.collaborativeInvoke = collaborativeSuccessStub({
      finalPlan: defaultFinalPlan("Collaborative Plan"),
      qualityScore: 93,
      debateRounds: 0,
      revisionCount: 2,
      validationIssues: ["qa:sample"],
      crossAgentChallenges: [
        {
          challengeId: "ch_strategist_analyst_missing_evidence_1",
          source: "strategist",
          target: "analyst",
          type: "missing_evidence",
          severity: "high",
        },
      ],
      consensusLog: [
        {
          round: 1,
          qualityScore: 93,
          unresolvedIssues: 1,
          unresolvedChallenges: 1,
          votes: [
            {
              role: "analyst",
              stance: "approve",
              confidence: 93,
              rationale: "round-1:validated",
            },
          ],
        },
      ],
      safeFallbackActivated: false,
    }).invoke;
  });

  it("includes additive phase4 metadata in collaborative API responses", async () => {
    const app = createTestApp();

    const res = await request(app)
      .post("/api/v1/ai/generate-plan")
      .set("Authorization", "Bearer test-token")
      .set("x-thread-id", "thread-phase4")
      .send({ user: { location: "India" }, appliances: [] });

    expect(res.status).toBe(200);
    expect(res.body.data.metadata.executionPath).toBe("collaborative");
    expect(res.body.data.metadata.qualityScore).toBe(93);
    expect(res.body.data.metadata.phase4).toEqual({
      revisionCount: 2,
      validationIssueCount: 1,
      challengeCount: 1,
      roleRetryBudgets: {
        analyst: 0,
        strategist: 0,
        copywriter: 0,
        challengeRouting: 0,
      },
    });
    expect(res.body.data.metadata.phase5).toEqual({
      qualityGate: {
        minScore: 85,
        passed: false,
      },
      consensusRoundCount: 1,
      consensusRationale: [
        {
          round: 1,
          qualityScore: 93,
          unresolvedIssues: 1,
          unresolvedChallenges: 1,
          votes: [
            {
              role: "analyst",
              stance: "approve",
              confidence: 93,
              rationale: "round-1:validated",
            },
          ],
        },
      ],
      safeFallbackActivated: false,
      consensusDecision: {
        stance: "revise",
        tieBreakApplied: false,
        tieBreakRule: null,
      },
      unresolvedRoute: "safe_fallback",
    });
  });
});
