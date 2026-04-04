const fs = require("fs");
const path = require("path");

const controllerPath = path.join(
  __dirname,
  "../src/controllers/support.controller.js",
);

describe("Support Retry Contract", () => {
  it("provides deterministic retry envelope on temporary failures", async () => {
    const exists = fs.existsSync(controllerPath);
    expect(exists).toBe(true);

    if (!exists) {
      return;
    }

    jest.resetModules();
    jest.doMock("../src/middleware/errorHandler", () => ({
      asyncHandler: (fn) => fn,
    }));
    jest.doMock("../src/utils/ApiResponse", () => ({
      sendSuccess: jest.fn(),
      sendError: jest.fn(),
    }));
    jest.doMock("../src/models/SupportTicket.model", () => ({
      create: jest.fn().mockRejectedValue(
        Object.assign(new Error("Upstream support platform unavailable"), {
          code: "TEMPORARY_UNAVAILABLE",
          retryAfterSeconds: 120,
        }),
      ),
    }));

    const supportController = require("../src/controllers/support.controller");

    const req = {
      id: "req-support-retry-1",
      body: {
        category: "billing",
        message: "Payment did not reflect.",
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
      },
      user: { _id: "user-1" },
    };
    const res = {
      setHeader: jest.fn(),
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    };

    await supportController.submitSupportTicket(req, res, jest.fn());

    expect(res.setHeader).toHaveBeenCalledWith("Retry-After", "120");

    const payload = res.json.mock.calls[0][0];
    expect(payload).toEqual(
      expect.objectContaining({
        success: false,
        errorCode: "TEMPORARY_UNAVAILABLE",
        requestId: "req-support-retry-1",
      }),
    );
  });
});
