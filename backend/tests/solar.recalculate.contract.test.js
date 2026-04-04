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

describe("Solar Recalculate Contract - SOL-03", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("recomputes deterministic ranges when inputs change", async () => {
    expect(fs.existsSync(controllerPath)).toBe(true);

    if (!fs.existsSync(controllerPath)) {
      return;
    }

    const { calculateSolarEstimate } = require(controllerPath);

    const reqA = {
      body: {
        monthlyUnits: 300,
        roofArea: 700,
        state: "Maharashtra",
        discom: "MSEDCL",
        shadingLevel: "low",
      },
      id: "req-solar-a",
    };

    const reqB = {
      body: {
        monthlyUnits: 600,
        roofArea: 1200,
        state: "Maharashtra",
        discom: "MSEDCL",
        shadingLevel: "high",
      },
      id: "req-solar-b",
    };

    await calculateSolarEstimate(reqA, {}, jest.fn());
    await calculateSolarEstimate(reqB, {}, jest.fn());

    const payloadA = sendSuccess.mock.calls[0][3];
    const payloadB = sendSuccess.mock.calls[1][3];

    expect(payloadA.estimatedMonthlyGenerationKwh.base).not.toBe(
      payloadB.estimatedMonthlyGenerationKwh.base,
    );

    jest.clearAllMocks();

    await calculateSolarEstimate(reqA, {}, jest.fn());
    const payloadARepeat = sendSuccess.mock.calls[0][3];

    expect(payloadARepeat.estimatedMonthlyGenerationKwh).toEqual(
      payloadA.estimatedMonthlyGenerationKwh,
    );
    expect(payloadARepeat.recommendedSystemSizeKw).toBe(
      payloadA.recommendedSystemSizeKw,
    );
  });
});
