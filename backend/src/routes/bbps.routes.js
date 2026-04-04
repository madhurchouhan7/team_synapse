// src/routes/bbps.routes.js
const express = require('express');
const router = express.Router();
const bbpsController = require('../controllers/bbps.controller');
const authMiddleware = require('../middleware/authMiddleware');

// Protected: BBPS bill fetch must be tied to an authenticated user context
router.post('/fetch-bill', authMiddleware, bbpsController.fetchBill);

module.exports = router;
