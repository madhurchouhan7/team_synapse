// src/routes/content.routes.js
// Routes for utility content surfaces.

const express = require("express");

const { validate } = require("../middleware/validation.middleware");
const contentController = require("../controllers/content.controller");

const router = express.Router();

router.get(
  "/faqs",
  validate("getFaqContent", "query"),
  contentController.getFaqs,
);
router.get(
  "/bill-guide",
  validate("getBillGuideContent", "query"),
  contentController.getBillGuide,
);
router.get(
  "/legal/:slug",
  validate("getLegalContent", "params"),
  contentController.getLegalContent,
);

module.exports = router;
