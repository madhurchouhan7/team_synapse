// src/routes/auth.routes.js
// Auth routes — Firebase handles actual sign-up/sign-in.
// This router exposes a /sync endpoint that the Flutter app calls immediately
// after a successful Firebase sign-in to create/fetch the MongoDB profile.

const express = require('express');
const router = express.Router();

const authMiddleware = require('../middleware/authMiddleware');
const authController = require('../controllers/auth.controller');

// POST /api/v1/auth/sync
// Protected: requires a valid Firebase ID Token in Authorization header
router.post('/sync', authMiddleware, authController.syncUser);

module.exports = router;
