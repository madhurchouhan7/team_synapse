jest.mock("../src/middleware/errorHandler", () => ({
  asyncHandler: (fn) => fn,
}));

jest.mock("../src/models/Appliance.model", () => ({
  findOne: jest.fn(),
  findOneAndUpdate: jest.fn(),
}));

const applianceController = require("../src/controllers/appliance.controller");
const Appliance = require("../src/models/Appliance.model");

const createMockRes = () => ({
  status: jest.fn().mockReturnThis(),
  json: jest.fn().mockReturnThis(),
});

describe("Appliance Concurrency Contract (APP-04)", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("stale patch updates must fail with 412 precondition for safe retry", async () => {
    Appliance.findOneAndUpdate.mockResolvedValue(null);
    Appliance.findOne.mockResolvedValue({ _id: "a-1", __v: 8 });

    const req = {
      id: "req-concurrency-1",
      params: { id: "a-1" },
      user: { _id: "user-1" },
      headers: { "if-match": '"7"' },
      body: {
        title: "AC Main Hall",
        _expectedVersion: 7,
      },
    };

    const res = createMockRes();

    await applianceController.updateAppliance(req, res, jest.fn());

    expect(res.status).toHaveBeenCalledWith(412);
    const payload = res.json.mock.calls[0][0];
    expect(payload).toEqual(
      expect.objectContaining({
        success: false,
        errorCode: "PRECONDITION_FAILED",
        requestId: "req-concurrency-1",
        message: expect.stringMatching(/precondition|stale|conflict/i),
        timestamp: expect.any(String),
      }),
    );
  });

  it("stale delete must fail with deterministic 412 envelope", async () => {
    Appliance.findOneAndUpdate.mockResolvedValue(null);
    Appliance.findOne.mockResolvedValue({ _id: "a-1", __v: 3 });

    const req = {
      id: "req-concurrency-2",
      params: { id: "a-1" },
      user: { _id: "user-1" },
      body: { _expectedVersion: 2 },
    };
    const res = createMockRes();

    await applianceController.deleteAppliance(req, res, jest.fn());

    expect(res.status).toHaveBeenCalledWith(412);
    const payload = res.json.mock.calls[0][0];
    expect(payload).toEqual(
      expect.objectContaining({
        success: false,
        errorCode: "PRECONDITION_FAILED",
        requestId: "req-concurrency-2",
        message: expect.stringMatching(/precondition|stale|conflict/i),
        timestamp: expect.any(String),
      }),
    );
  });
});
