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
  legacySuccessStub,
  collaborativeSuccessStub,
  defaultFinalPlan,
} = require("./helpers/mockOrchestrators");

function createTestApp() {
  const app = express();
  app.use((req, _res, next) => {
    req.id = "req-test-routing";
    next();
  });
  app.use(express.json());
  app.use("/api/v1/ai", aiRoutes);
  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
}

describe("AI compatibility - routing matrix", () => {
  beforeEach(() => {
    process.env.OPENWEATHER_API_KEY = "";
    mockOrchestrators.legacyInvoke = legacySuccessStub(
      defaultFinalPlan("Legacy Plan"),
    ).invoke;
    mockOrchestrators.collaborativeInvoke = collaborativeSuccessStub({
      finalPlan: defaultFinalPlan("Collaborative Plan"),
      qualityScore: 91,
      debateRounds: 3,
    }).invoke;
  });

  it("uses collaborative path by default in non-production", async () => {
    process.env.NODE_ENV = "development";
    const app = createTestApp();

    const res = await request(app)
      .post("/api/v1/ai/generate-plan")
      .set("Authorization", "Bearer test-token")
      .send({ user: { location: "India" }, appliances: [] });

    expect(res.status).toBe(200);
    expect(res.body.data.metadata.executionPath).toBe("collaborative");
    expect(res.body.data.metadata.requestedMode).toBe("collaborative");
    expect(res.body.data.metadata.qualityScore).toBe(91);
    expect(res.body.data.metadata.debateRounds).toBe(3);
    expect(mockOrchestrators.collaborativeInvoke).toHaveBeenCalledTimes(1);
    expect(mockOrchestrators.legacyInvoke).not.toHaveBeenCalled();
  });

  it("supports explicit header override to legacy in development", async () => {
    process.env.NODE_ENV = "development";
    const app = createTestApp();

    const res = await request(app)
      .post("/api/v1/ai/generate-plan")
      .set("Authorization", "Bearer test-token")
      .set("x-ai-mode", "legacy")
      .send({ user: { location: "India" }, appliances: [] });

    expect(res.status).toBe(200);
    expect(res.body.data.metadata.executionPath).toBe("legacy");
    expect(res.body.data.metadata.requestedMode).toBe("legacy");
    expect(mockOrchestrators.legacyInvoke).toHaveBeenCalledTimes(1);
  });

  it("returns 400 for invalid x-ai-mode values", async () => {
    process.env.NODE_ENV = "development";
    const app = createTestApp();

    const res = await request(app)
      .post("/api/v1/ai/generate-plan")
      .set("Authorization", "Bearer test-token")
      .set("x-ai-mode", "invalid-mode")
      .send({ user: { location: "India" }, appliances: [] });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.errorCode).toBe("API_ERROR");
    expect(res.body.message).toContain("Allowed values: legacy, collaborative");
  });
});
