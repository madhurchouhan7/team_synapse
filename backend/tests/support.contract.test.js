const fs = require("fs");
const path = require("path");

const { validate } = require("../src/middleware/validation.middleware");

const runSupportValidation = async (body) => {
  const req = {
    id: "req-support-1",
    body,
  };
  const res = {
    status: jest.fn().mockReturnThis(),
    json: jest.fn().mockReturnThis(),
  };
  const next = jest.fn();

  await validate("createSupportTicket")(req, res, next);

  return { req, res, next };
};

describe("Support Contract - /api/v1/support/tickets", () => {
  it("returns 400 VALIDATION_ERROR with details[] for missing required fields", async () => {
    const { res, next } = await runSupportValidation({});

    expect(next).not.toHaveBeenCalled();
    expect(res.status).toHaveBeenCalledWith(400);

    const payload = res.json.mock.calls[0][0];
    expect(payload).toEqual(
      expect.objectContaining({
        success: false,
        message: "Validation failed",
        errorCode: "VALIDATION_ERROR",
        requestId: "req-support-1",
        details: expect.any(Array),
      }),
    );
    expect(payload.details).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ path: "category" }),
        expect.objectContaining({ path: "message" }),
        expect.objectContaining({ path: "preferredContact" }),
      ]),
    );
  });

  it("accepts valid support payload contract", async () => {
    const validPayload = {
      category: "billing",
      message: "I was charged twice for the same billing period.",
      preferredContact: {
        name: "Madhur",
        method: "email",
        email: "madhur@example.com",
      },
      consent: {
        policySlug: "support-privacy",
        consentVersion: "2026.03",
        acceptedAt: "2026-03-27T00:00:00.000Z",
      },
    };

    const { req, res, next } = await runSupportValidation(validPayload);

    expect(next).toHaveBeenCalledTimes(1);
    expect(res.status).not.toHaveBeenCalled();
    expect(req.body).toEqual(validPayload);
  });

  it("mounts /support namespace in API router", () => {
    const routeIndexPath = path.join(__dirname, "../src/routes/index.js");
    const routeIndexSource = fs.readFileSync(routeIndexPath, "utf8");

    expect(routeIndexSource).toMatch(
      /router\.use\(["']\/support["'],\s*supportRoutes\)/,
    );
  });
});
