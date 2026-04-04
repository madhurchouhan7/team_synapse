jest.mock("../src/middleware/errorHandler", () => ({
  asyncHandler: (fn) => fn,
}));

jest.mock("../src/utils/ApiResponse", () => ({
  sendSuccess: jest.fn(),
}));

jest.mock("../src/models/Appliance.model", () => ({
  updateMany: jest.fn(),
  insertMany: jest.fn(),
}));

const applianceController = require("../src/controllers/appliance.controller");
const Appliance = require("../src/models/Appliance.model");

describe("Appliance Non-Destructive Contract (APP-02)", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    Appliance.updateMany.mockResolvedValue({
      acknowledged: true,
      modifiedCount: 1,
    });
    Appliance.insertMany.mockResolvedValue([
      { applianceId: "ac-1", title: "Updated AC" },
    ]);
  });

  it("bulk update must scope deactivation to touched appliance IDs only", async () => {
    const req = {
      user: { _id: "user-1" },
      body: {
        appliances: [
          {
            applianceId: "ac-1",
            title: "Updated AC",
            category: "cooling",
            usageLevel: "Medium",
            usageHours: 4,
            count: 1,
            selectedDropdowns: {},
          },
        ],
      },
    };

    await applianceController.updateAppliancesBulk(req, {}, jest.fn());

    // RED-first contract: this should fail on current implementation that deactivates all active appliances.
    expect(Appliance.updateMany).toHaveBeenCalledWith(
      {
        userId: "user-1",
        isActive: true,
        applianceId: { $in: ["ac-1"] },
      },
      { isActive: false },
    );
  });
});
