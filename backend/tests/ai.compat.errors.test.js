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
const ApiError = require("../src/utils/ApiError");
const {
  legacySuccessStub,
  collaborativeFailureStub,
  defaultFinalPlan,
} = require("./helpers/mockOrchestrators");

function createTestApp() {
  const app = express();
  app.use((req, _res, next) => {
    req.id = "req-test-errors";
    next();
  });
  app.use(express.json());
  app.use("/api/v1/ai", aiRoutes);
  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
}

describe("AI compatibility - centralized error path", () => {
  beforeEach(() => {
    process.env.OPENWEATHER_API_KEY = "";
    mockOrchestrators.legacyInvoke = legacySuccessStub(
      defaultFinalPlan("Legacy Fallback Candidate"),
    ).invoke;
    mockOrchestrators.collaborativeInvoke = collaborativeFailureStub(
      new ApiError(500, "Collaborative path failed"),
    ).invoke;
  });

  it("returns centralized 500 payload on collaborative failure and does not fallback", async () => {
    process.env.NODE_ENV = "development";
    const app = createTestApp();

    const res = await request(app)
      .post("/api/v1/ai/generate-plan")
      .set("Authorization", "Bearer test-token")
      .set("x-ai-mode", "collaborative")
      .send({ user: { location: "India" }, appliances: [] });

    expect(res.status).toBe(500);
    expect(res.body.success).toBe(false);
    expect(res.body.errorCode).toBe("API_ERROR");
    expect(res.body.requestId).toBe("req-test-errors");
    expect(mockOrchestrators.collaborativeInvoke).toHaveBeenCalledTimes(1);
    expect(mockOrchestrators.legacyInvoke).not.toHaveBeenCalled();
  });

  it("returns structured 400 error for invalid mode values", async () => {
    process.env.NODE_ENV = "development";
    const app = createTestApp();

    const res = await request(app)
      .post("/api/v1/ai/generate-plan")
      .set("Authorization", "Bearer test-token")
      .set("x-ai-mode", "totally-bad")
      .send({ user: { location: "India" }, appliances: [] });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.errorCode).toBe("API_ERROR");
    expect(res.body.requestId).toBe("req-test-errors");
    expect(res.body.message).toContain("Allowed values: legacy, collaborative");
  });
});
