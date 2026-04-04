const express = require("express");

const authMiddleware = require("../middleware/authMiddleware");
const { rateLimiters } = require("../middleware/rateLimit.middleware");
const { validate } = require("../middleware/validation.middleware");
const { submitSupportTicket } = require("../controllers/support.controller");

const router = express.Router();

router.use(authMiddleware);

router.post(
  "/tickets",
  rateLimiters.strict,
  validate("createSupportTicket"),
  submitSupportTicket,
);

module.exports = router;
