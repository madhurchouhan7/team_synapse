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

describe("Solar Limitations Contract - SOL-04", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("always includes limitations, confidenceLabel, and disclaimer", async () => {
    expect(fs.existsSync(controllerPath)).toBe(true);

    if (!fs.existsSync(controllerPath)) {
      return;
    }

    const { calculateSolarEstimate } = require(controllerPath);

    await calculateSolarEstimate(
      {
        body: {
          monthlyUnits: 420,
          roofArea: 850,
          state: "Karnataka",
          discom: "BESCOM",
          shadingLevel: "medium",
        },
        id: "req-solar-limits",
      },
      {},
      jest.fn(),
    );

    const payload = sendSuccess.mock.calls[0][3];

    expect(Array.isArray(payload.limitations)).toBe(true);
    expect(payload.limitations.length).toBeGreaterThan(0);
    expect(payload.confidenceLabel).toMatch(/LOW|MEDIUM/);
    expect(payload.disclaimer).toEqual(expect.any(String));
    expect(payload.disclaimer.toLowerCase()).toContain("estimate");
  });
});
