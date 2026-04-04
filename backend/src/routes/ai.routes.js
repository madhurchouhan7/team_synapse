// src/routes/ai.routes.js
const express = require('express');
const { getEfficiencyPlan } = require('../controllers/ai.controller');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

// Generate AI Efficiency Plan based on user stats
router.post('/generate-plan', authMiddleware, getEfficiencyPlan);

module.exports = router;
