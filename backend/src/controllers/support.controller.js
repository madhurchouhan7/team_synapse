const crypto = require("crypto");

const SupportTicket = require("../models/SupportTicket.model");
const { sendSuccess, sendError } = require("../utils/ApiResponse");
const { asyncHandler } = require("../middleware/errorHandler");

const createTicketRef = () => {
  const stamp = new Date().toISOString().slice(0, 10).replace(/-/g, "");
  const suffix = crypto.randomBytes(3).toString("hex").toUpperCase();
  return `SUP-${stamp}-${suffix}`;
};

const sendRetryableFailure = (req, res, retryAfterSeconds) => {
  if (retryAfterSeconds) {
    res.setHeader("Retry-After", String(retryAfterSeconds));
  }

  return res.status(503).json({
    success: false,
    message: "Support service is temporarily unavailable. Please retry.",
    errorCode: "TEMPORARY_UNAVAILABLE",
    requestId: req.id,
    timestamp: new Date().toISOString(),
    retryAfterSeconds: retryAfterSeconds || undefined,
  });
};

const submitSupportTicket = asyncHandler(async (req, res) => {
  const now = new Date();
  const { category, message, preferredContact, consent } = req.body;

  try {
    const created = await SupportTicket.create({
      ticketRef: createTicketRef(),
      userId: req.user?._id,
      category,
      message,
      preferredContact,
      status: "OPEN",
      consent: {
        policySlug: consent.policySlug,
        consentVersion: consent.consentVersion,
        acceptedAt: new Date(consent.acceptedAt),
      },
      trace: {
        requestId: req.id,
        submittedAt: now,
      },
    });

    return sendSuccess(res, 201, "Support ticket submitted successfully.", {
      ticketRef: created.ticketRef,
      status: created.status,
      requestId: req.id,
      timestamp: now.toISOString(),
    });
  } catch (error) {
    if (error.code === "TEMPORARY_UNAVAILABLE") {
      return sendRetryableFailure(req, res, error.retryAfterSeconds);
    }

    return sendError(
      res,
      500,
      "Unable to submit support ticket. Please retry shortly.",
    );
  }
});

module.exports = {
  submitSupportTicket,
};
