// src/routes/user.routes.js
// User profile routes (protected)

const express = require("express");
const router = express.Router();

const authMiddleware = require("../middleware/authMiddleware");
const { validate } = require("../middleware/validation.middleware");
const userController = require("../controllers/user.controller");

// All routes below require a valid JWT
router.use(authMiddleware);

// GET  /api/v1/users/me  — get current user profile
router.get("/me", userController.getMe);

// PUT  /api/v1/users/me  — update current user profile
router.put("/me", validate("updateProfile"), userController.updateMe);

// GET  /api/v1/users/me/streak  — get current streak data
router.get("/me/streak", userController.getStreak);

// POST /api/v1/users/me/streak  — record a daily check-in
router.post("/me/streak", userController.checkIn);

// POST /api/v1/users/me/heatmap  — record or update today's heatmap intensity
router.post("/me/heatmap", userController.updateHeatmap);

// GET  /api/v1/users/me/heatmap  — fetch the heatmap for the given month
router.get("/me/heatmap", userController.getHeatmap);

// GET  /api/v1/users/me/active-plan  — get active plan (large payload, on-demand only)
router.get("/me/active-plan", userController.getActivePlan);

// PUT  /api/v1/users/me/appliances — update user's selected appliances
router.put("/me/appliances", userController.updateAppliances);

// POST /api/v1/users/me/bills — add a new bill
router.post("/me/bills", userController.addBill);

module.exports = router;
