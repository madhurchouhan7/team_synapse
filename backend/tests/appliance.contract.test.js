jest.mock("../src/middleware/errorHandler", () => ({
  asyncHandler: (fn) => fn,
}));

jest.mock("../src/utils/ApiResponse", () => ({
  sendSuccess: jest.fn(),
}));

jest.mock("../src/models/Appliance.model", () => ({
  create: jest.fn(),
  findOne: jest.fn(),
  findOneAndUpdate: jest.fn(),
}));

const applianceController = require("../src/controllers/appliance.controller");
const Appliance = require("../src/models/Appliance.model");
const { sendSuccess } = require("../src/utils/ApiResponse");
const ApiError = require("../src/utils/ApiError");

describe("Appliance Contract - create/update/delete envelopes", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("returns deterministic success envelope for create", async () => {
    const created = {
      _id: "a-1",
      applianceId: "ac-1",
      title: "Air Conditioner",
      category: "cooling",
      usageLevel: "Medium",
      userId: "user-1",
    };

    Appliance.create.mockResolvedValue(created);

    const req = {
      body: {
        applianceId: "ac-1",
        title: "Air Conditioner",
        category: "cooling",
        usageLevel: "Medium",
      },
      user: { _id: "user-1" },
    };
    const res = {};

    await applianceController.createAppliance(req, res, jest.fn());

    expect(Appliance.create).toHaveBeenCalledWith(
      expect.objectContaining({
        applianceId: "ac-1",
        userId: "user-1",
      }),
    );
    expect(sendSuccess).toHaveBeenCalledWith(
      res,
      201,
      "Appliance created successfully.",
      created,
    );
  });

  it("returns deterministic success envelope for update", async () => {
    const updated = {
      _id: "a-1",
      applianceId: "ac-1",
      title: "AC Bedroom",
      userId: "user-1",
      isActive: true,
      __v: 3,
    };

    Appliance.findOneAndUpdate.mockResolvedValue(updated);

    const req = {
      params: { id: "a-1" },
      user: { _id: "user-1" },
      body: { title: "AC Bedroom", _expectedVersion: 2 },
    };
    const res = {};

    await applianceController.updateAppliance(req, res, jest.fn());

    expect(Appliance.findOneAndUpdate).toHaveBeenCalledWith(
      { _id: "a-1", userId: "user-1", isActive: true, __v: 2 },
      {
        $set: expect.objectContaining({
          title: "AC Bedroom",
          lastUpdated: expect.any(Date),
        }),
        $inc: { __v: 1 },
      },
      { returnDocument: "after", runValidators: true },
    );
    expect(sendSuccess).toHaveBeenCalledWith(
      res,
      200,
      "Appliance updated successfully.",
      updated,
    );
  });

  it("returns deterministic success envelope for delete", async () => {
    Appliance.findOneAndUpdate.mockResolvedValue({ _id: "a-1", __v: 4 });

    const req = {
      params: { id: "a-1" },
      user: { _id: "user-1" },
      body: { _expectedVersion: 3 },
    };
    const res = {};

    await applianceController.deleteAppliance(req, res, jest.fn());

    expect(Appliance.findOneAndUpdate).toHaveBeenCalledWith(
      { _id: "a-1", userId: "user-1", isActive: true, __v: 3 },
      {
        $set: expect.objectContaining({
          isActive: false,
          lastUpdated: expect.any(Date),
        }),
        $inc: { __v: 1 },
      },
      { returnDocument: "after", runValidators: true },
    );

    expect(sendSuccess).toHaveBeenCalledWith(
      res,
      200,
      "Appliance deleted successfully.",
    );
  });

  it("returns 404 ApiError when patch target appliance does not exist", async () => {
    Appliance.findOneAndUpdate.mockResolvedValue(null);
    Appliance.findOne.mockResolvedValue(null);

    const req = {
      params: { id: "missing-appliance" },
      user: { _id: "user-1" },
      body: { title: "Missing", _expectedVersion: 0 },
    };

    await expect(
      applianceController.updateAppliance(req, {}, jest.fn()),
    ).rejects.toMatchObject({
      statusCode: 404,
      message: "Appliance not found.",
    });

    await expect(
      applianceController.updateAppliance(req, {}, jest.fn()),
    ).rejects.toBeInstanceOf(ApiError);
  });
});
