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
    req.id = "req-test-legacy";
    next();
  });
  app.use(express.json());
  app.use("/api/v1/ai", aiRoutes);
  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
}

describe("AI compatibility - legacy parity", () => {
  beforeEach(() => {
    process.env.OPENWEATHER_API_KEY = "";
    mockOrchestrators.legacyInvoke = legacySuccessStub(
      defaultFinalPlan("Legacy Expected"),
    ).invoke;
    mockOrchestrators.collaborativeInvoke = collaborativeSuccessStub().invoke;
  });

  it("uses legacy path by default in production and preserves finalPlan compatibility", async () => {
    process.env.NODE_ENV = "production";
    const app = createTestApp();

    const res = await request(app)
      .post("/api/v1/ai/generate-plan")
      .set("Authorization", "Bearer test-token")
      .send({ user: { location: "India" }, appliances: [] });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.finalPlan.title).toBe("Legacy Expected");
    expect(res.body.data.metadata.executionPath).toBe("legacy");
    expect(res.body.data.metadata.requestedMode).toBe("legacy");
    expect(res.body.data.metadata.orchestrationVersion).toBe("v2-phase2");
    expect(mockOrchestrators.legacyInvoke).toHaveBeenCalledTimes(1);
    expect(mockOrchestrators.collaborativeInvoke).not.toHaveBeenCalled();
  });

  it("honors explicit legacy mode header in development", async () => {
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
    expect(mockOrchestrators.collaborativeInvoke).not.toHaveBeenCalled();
  });
});
