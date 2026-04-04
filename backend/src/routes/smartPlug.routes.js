// src/routes/smartPlug.routes.js
// Routes for Smart Plug management and telemetry

const express              = require('express');
const router               = express.Router();
const authMiddleware        = require('../middleware/authMiddleware');
const { rateLimiters }     = require('../middleware/rateLimit.middleware');
const { validate }         = require('../middleware/validation.middleware');
const smartPlugController  = require('../controllers/smartPlug.controller');

// All routes require authentication
router.use(authMiddleware);

// ─── Summary (must come before /:id) ─────────────────────────────────────────
// GET /api/v1/smart-plugs/summary
router.get('/summary', smartPlugController.getSummary);

// ─── Plug CRUD ────────────────────────────────────────────────────────────────

// POST /api/v1/smart-plugs — register a new plug
router.post(
  '/',
  rateLimiters.strict,
  validate('registerSmartPlug'),
  smartPlugController.registerPlug,
);

// GET /api/v1/smart-plugs — list all user's plugs
router.get('/', smartPlugController.getPlugs);

// GET /api/v1/smart-plugs/:id — get a single plug
router.get('/:id', smartPlugController.getPlug);

// DELETE /api/v1/smart-plugs/:id — unregister a plug
router.delete('/:id', rateLimiters.strict, smartPlugController.deletePlug);

// ─── Telemetry ────────────────────────────────────────────────────────────────

// GET /api/v1/smart-plugs/:id/telemetry — fetch readings history
router.get('/:id/telemetry', smartPlugController.getTelemetry);

// POST /api/v1/smart-plugs/:id/simulate — manually trigger one reading
router.post(
  '/:id/simulate',
  rateLimiters.strict,
  validate('triggerSmartPlugReading'),
  smartPlugController.triggerReading,
);

module.exports = router;
