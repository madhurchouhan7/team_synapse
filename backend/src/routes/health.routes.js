// src/routes/health.routes.js
// Health check routes for monitoring and diagnostics

const express = require('express');
const router = express.Router();
const healthController = require('../controllers/health.controller');

// ─── Health Check Routes ─────────────────────────────────────────────────────

// GET /health - Basic health check
router.get('/', healthController.basic);

// GET /health/detailed - Detailed health check with all components
router.get('/detailed', healthController.detailed);

// GET /health/ready - Readiness probe (for container orchestration)
router.get('/ready', healthController.readiness);

// GET /health/live - Liveness probe (for container orchestration)
router.get('/live', healthController.liveness);

// GET /health/metrics - Application metrics
router.get('/metrics', healthController.metrics);

module.exports = router;
