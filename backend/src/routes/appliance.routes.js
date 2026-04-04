// src/routes/appliance.routes.js
// Routes for appliance management

const express = require("express");
const router = express.Router();

const authMiddleware = require("../middleware/authMiddleware");
const { rateLimiters } = require("../middleware/rateLimit.middleware");
const { validate } = require("../middleware/validation.middleware");
const applianceController = require("../controllers/appliance.controller");

// Apply auth middleware to all routes
router.use(authMiddleware);

// ─── Appliance Routes ─────────────────────────────────────────────────────

// POST /api/v1/appliances - Create new appliance
router.post(
  "/",
  rateLimiters.strict,
  validate("createAppliance"),
  applianceController.createAppliance,
);

// GET /api/v1/appliances - Get all user appliances
router.get("/", applianceController.getAppliances);

// GET /api/v1/appliances/summary - Get appliance summary
router.get("/summary", applianceController.getApplianceSummary);

// GET /api/v1/appliances/categories - Get appliance categories
router.get("/categories", applianceController.getApplianceCategories);

// POST /api/v1/appliances/bulk - Bulk update appliances
router.post(
  "/bulk",
  rateLimiters.strict,
  validate("updateAppliances"),
  applianceController.updateAppliancesBulk,
);

// GET /api/v1/appliances/:id - Get specific appliance
router.get("/:id", applianceController.getAppliance);

// PATCH /api/v1/appliances/:id - Update appliance
router.patch(
  "/:id",
  rateLimiters.strict,
  validate("patchAppliance"),
  applianceController.updateAppliance,
);

// DELETE /api/v1/appliances/:id - Delete appliance
router.delete(
  "/:id",
  rateLimiters.strict,
  validate("deleteAppliance"),
  applianceController.deleteAppliance,
);

module.exports = router;
