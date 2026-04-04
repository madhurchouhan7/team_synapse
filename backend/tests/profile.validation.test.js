const { validate } = require("../src/middleware/validation.middleware");

const runUpdateProfileValidation = async (body) => {
  const req = {
    id: "req-1",
    body,
  };
  const res = {
    status: jest.fn().mockReturnThis(),
    json: jest.fn().mockReturnThis(),
  };
  const next = jest.fn();

  await validate("updateProfile")(req, res, next);

  return { req, res, next };
};

describe("Profile Validation Contract - /api/v1/users/me", () => {
  it("returns deterministic validation envelope with details for short name", async () => {
    const { res, next } = await runUpdateProfileValidation({ name: "A" });

    expect(next).not.toHaveBeenCalled();
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        success: false,
        errorCode: "VALIDATION_ERROR",
        message: "Validation failed",
        details: expect.arrayContaining([
          expect.objectContaining({
            path: "name",
            message: expect.any(String),
          }),
        ]),
      }),
    );
  });

  it("returns details path for malformed avatar URL", async () => {
    const { res } = await runUpdateProfileValidation({ avatarUrl: "not-a-url" });
    const payload = res.json.mock.calls[0][0];

    expect(payload.details).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          path: "avatarUrl",
          message: expect.any(String),
        }),
      ]),
    );
  });

  it("rejects unsupported fields with deterministic details", async () => {
    const { res } = await runUpdateProfileValidation({ monthlyBudget: 1000 });
    const payload = res.json.mock.calls[0][0];

    expect(payload.details).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          path: "monthlyBudget",
          message: expect.stringContaining("Unsupported field"),
        }),
      ]),
    );
  });
});
