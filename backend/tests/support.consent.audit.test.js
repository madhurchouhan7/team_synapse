const fs = require("fs");
const path = require("path");

const controllerPath = path.join(
  __dirname,
  "../src/controllers/support.controller.js",
);

describe("Support Consent Audit Contract", () => {
  it("persists consent snapshot and includes trace metadata", async () => {
    const exists = fs.existsSync(controllerPath);
    expect(exists).toBe(true);

    if (!exists) {
      return;
    }

    jest.resetModules();
    const createdTicket = {
      _id: "ticket-1",
      ticketRef: "SUP-20260327-ABC123",
      status: "OPEN",
      consent: {
        policySlug: "support-privacy",
        consentVersion: "2026.03",
        acceptedAt: new Date("2026-03-27T00:00:00.000Z"),
      },
      trace: {
        requestId: "req-support-audit-1",
        submittedAt: new Date("2026-03-27T00:00:01.000Z"),
      },
    };

    jest.doMock("../src/middleware/errorHandler", () => ({
      asyncHandler: (fn) => fn,
    }));
    jest.doMock("../src/models/SupportTicket.model", () => ({
      create: jest.fn().mockResolvedValue(createdTicket),
    }));
    jest.doMock("../src/utils/ApiResponse", () => ({
      sendSuccess: jest.fn(),
      sendError: jest.fn(),
    }));

    const SupportTicket = require("../src/models/SupportTicket.model");
    const { sendSuccess } = require("../src/utils/ApiResponse");
    const supportController = require("../src/controllers/support.controller");

    const req = {
      id: "req-support-audit-1",
      body: {
        category: "legal",
        message: "Need policy clarification for billing dispute.",
        preferredContact: {
          name: "Madhur",
          method: "phone",
          phone: "9876543210",
        },
        consent: {
          policySlug: "support-privacy",
          consentVersion: "2026.03",
          acceptedAt: "2026-03-27T00:00:00.000Z",
        },
      },
      user: { _id: "user-1" },
    };
    const res = {};

    await supportController.submitSupportTicket(req, res, jest.fn());

    expect(SupportTicket.create).toHaveBeenCalledWith(
      expect.objectContaining({
        consent: expect.objectContaining({
          policySlug: "support-privacy",
          consentVersion: "2026.03",
        }),
        trace: expect.objectContaining({ requestId: "req-support-audit-1" }),
      }),
    );
    expect(sendSuccess).toHaveBeenCalledWith(
      res,
      201,
      "Support ticket submitted successfully.",
      expect.objectContaining({
        ticketRef: createdTicket.ticketRef,
        status: "OPEN",
      }),
    );
  });
});
