const {
  validate,
  schemas,
} = require("../src/middleware/validation.middleware");

const runSolarValidation = async (body) => {
  const req = {
    id: "req-solar-validation",
    body,
  };
  const res = {
    status: jest.fn().mockReturnThis(),
    json: jest.fn().mockReturnThis(),
  };
  const next = jest.fn();

  await validate("calculateSolarEstimate")(req, res, next);

  return { req, res, next };
};

describe("Solar Validation Contract - /api/v1/solar/estimate", () => {
  it("exposes calculateSolarEstimate schema contract", () => {
    expect(schemas).toHaveProperty("calculateSolarEstimate");
  });

  it("returns 400 VALIDATION_ERROR when required fields are missing (SOL-01)", async () => {
    const { res, next } = await runSolarValidation({});

    expect(next).not.toHaveBeenCalled();
    expect(res.status).toHaveBeenCalledWith(400);

    const payload = res.json.mock.calls[0][0];
    expect(payload).toEqual(
      expect.objectContaining({
        success: false,
        errorCode: "VALIDATION_ERROR",
        message: "Validation failed",
      }),
    );

    expect(payload.details).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ path: "monthlyUnits" }),
        expect.objectContaining({ path: "roofArea" }),
        expect.objectContaining({ path: "state" }),
        expect.objectContaining({ path: "discom" }),
      ]),
    );
  });

  it("accepts bounded valid payload and passes to next middleware", async () => {
    const input = {
      monthlyUnits: 420,
      roofArea: 900,
      state: "Maharashtra",
      discom: "MSEDCL",
      shadingLevel: "medium",
    };

    const { req, res, next } = await runSolarValidation(input);

    expect(res.status).not.toHaveBeenCalled();
    expect(next).toHaveBeenCalledTimes(1);
    expect(req.body).toEqual(expect.objectContaining(input));
  });
});
