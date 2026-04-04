// src/routes/simulation.routes.js

const express = require('express');
const router  = express.Router();
const auth    = require('../middleware/authMiddleware');
const { rateLimiters } = require('../middleware/rateLimit.middleware');
const ctrl    = require('../controllers/simulation.controller');

router.use(auth);

// GET  /api/v1/simulation/status         — current scenario, plug states, WS clients
router.get('/status',              ctrl.getStatus);

// GET  /api/v1/simulation/scenarios      — list all available scenarios
router.get('/scenarios',           ctrl.listScenarios);

// POST /api/v1/simulation/scenario       — change active scenario
router.post('/scenario',           rateLimiters.strict, ctrl.setScenario);

// POST /api/v1/simulation/plug/:id/trigger  — manual reading trigger
router.post('/plug/:id/trigger',   rateLimiters.strict, ctrl.triggerPlug);

// POST /api/v1/simulation/plug/:id/state    — force device state
router.post('/plug/:id/state',     rateLimiters.strict, ctrl.forcePlugState);

// DELETE /api/v1/simulation/plug/:id/reset  — reset simulation state
router.delete('/plug/:id/reset',   ctrl.resetPlugState);

module.exports = router;
