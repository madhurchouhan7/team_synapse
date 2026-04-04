const fs = require("fs");
const path = require("path");

jest.mock("../src/middleware/errorHandler", () => ({
  asyncHandler: (fn) => fn,
}));

jest.mock("../src/utils/ApiResponse", () => ({
  sendSuccess: jest.fn(),
}));

const { sendSuccess } = require("../src/utils/ApiResponse");

const controllerPath = path.join(
  __dirname,
  "../src/controllers/solar.controller.js",
);
const solarRoutesPath = path.join(__dirname, "../src/routes/solar.routes.js");

describe("Solar Range Contract - SOL-02", () => {
  it("mounts /solar namespace in api router", () => {
    const routeIndexPath = path.join(__dirname, "../src/routes/index.js");
    const source = fs.readFileSync(routeIndexPath, "utf8");

    expect(source).toMatch(/router\.use\(["']\/solar["'],\s*solarRoutes\)/);
  });

  it("provides solar routes module with POST /estimate", () => {
    expect(fs.existsSync(solarRoutesPath)).toBe(true);

    if (!fs.existsSync(solarRoutesPath)) {
      return;
    }

    const solarRouter = require(solarRoutesPath);
    const estimateRoute = solarRouter.stack.find(
      (layer) => layer.route && layer.route.path === "/estimate",
    );

    expect(estimateRoute).toBeDefined();
    expect(estimateRoute.route.methods.post).toBe(true);
  });

  it("returns low/base/high ranges and assumptions object", async () => {
    expect(fs.existsSync(controllerPath)).toBe(true);

    if (!fs.existsSync(controllerPath)) {
      return;
    }

    const { calculateSolarEstimate } = require(controllerPath);
    const req = {
      body: {
        monthlyUnits: 450,
        roofArea: 1000,
        state: "Maharashtra",
        discom: "MSEDCL",
        shadingLevel: "medium",
      },
      id: "req-solar-range",
    };

    await calculateSolarEstimate(req, {}, jest.fn());

    const responsePayload = sendSuccess.mock.calls[0][3];
    expect(responsePayload).toEqual(
      expect.objectContaining({
        estimatedMonthlyGenerationKwh: expect.objectContaining({
          low: expect.any(Number),
          base: expect.any(Number),
          high: expect.any(Number),
        }),
        assumptions: expect.any(Object),
      }),
    );
  });
});
