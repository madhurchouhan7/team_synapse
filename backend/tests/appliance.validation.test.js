const { validate } = require("../src/middleware/validation.middleware");

const runApplianceValidation = async (schemaName, body) => {
  const req = { id: "req-1", body };
  const res = {
    status: jest.fn().mockReturnThis(),
    json: jest.fn().mockReturnThis(),
  };
  const next = jest.fn();

  await validate(schemaName)(req, res, next);

  return { req, res, next };
};

describe("Appliance Validation Contract", () => {
  it("returns details[] path for invalid usage hours", async () => {
    const { res, next } = await runApplianceValidation("updateAppliances", {
      appliances: [
        {
          applianceId: "ac-1",
          title: "Air Conditioner",
          category: "cooling",
          usageHours: 30,
          usageLevel: "High",
          count: 1,
          selectedDropdowns: {},
        },
      ],
    });

    expect(next).not.toHaveBeenCalled();
    expect(res.status).toHaveBeenCalledWith(400);

    const payload = res.json.mock.calls[0][0];
    expect(payload.errorCode).toBe("VALIDATION_ERROR");
    expect(payload.details).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          path: "appliances.0.usageHours",
          message: expect.any(String),
        }),
      ]),
    );
  });

  it("returns deterministic validation envelope when appliances array is missing", async () => {
    const { res } = await runApplianceValidation("updateAppliances", {});
    const payload = res.json.mock.calls[0][0];

    expect(payload).toEqual(
      expect.objectContaining({
        success: false,
        message: "Validation failed",
        errorCode: "VALIDATION_ERROR",
        details: expect.any(Array),
      }),
    );
    expect(payload.details).toEqual(
      expect.arrayContaining([expect.objectContaining({ path: "appliances" })]),
    );
  });

  it("rejects unknown create fields with deterministic details", async () => {
    const { res, next } = await runApplianceValidation("createAppliance", {
      applianceId: "ac-2",
      title: "Bedroom AC",
      category: "cooling",
      usageLevel: "Medium",
      unsupportedField: "should-fail",
    });

    expect(next).not.toHaveBeenCalled();
    expect(res.status).toHaveBeenCalledWith(400);

    const payload = res.json.mock.calls[0][0];
    expect(payload.errorCode).toBe("VALIDATION_ERROR");
    expect(payload.details).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          path: "unsupportedField",
          message: "Unsupported field",
        }),
      ]),
    );
  });

  it("accepts patch payload with partial mutable fields only", async () => {
    const { res, next, req } = await runApplianceValidation("patchAppliance", {
      title: "AC Master Bedroom",
      usageHoursPerDay: 6,
      _expectedVersion: 2,
    });

    expect(next).toHaveBeenCalledTimes(1);
    expect(res.status).not.toHaveBeenCalled();
    expect(req.body).toEqual({
      title: "AC Master Bedroom",
      usageHoursPerDay: 6,
      _expectedVersion: 2,
    });
  });

  it("requires version precondition for delete contract", async () => {
    const { res, next } = await runApplianceValidation("deleteAppliance", {});

    expect(next).not.toHaveBeenCalled();
    expect(res.status).toHaveBeenCalledWith(400);

    const payload = res.json.mock.calls[0][0];
    expect(payload.errorCode).toBe("VALIDATION_ERROR");
    expect(payload.details).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ path: "_expectedVersion" }),
      ]),
    );
  });
});
