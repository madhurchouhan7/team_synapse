// src/routes/address.routes.js
// Routes for address management

const express = require('express');
const router = express.Router();

const authMiddleware = require('../middleware/authMiddleware');
const { validate } = require('../middleware/validation.middleware');
const addressController = require('../controllers/address.controller');

// Apply auth middleware to all routes
router.use(authMiddleware);

// ─── Address Routes ─────────────────────────────────────────────────────

// POST /api/v1/addresses - Create new address
router.post('/',
    validate('updateAddress'),
    addressController.createAddress
);

// GET /api/v1/addresses - Get all user addresses
router.get('/', addressController.getAddresses);

// GET /api/v1/addresses/:id - Get specific address
router.get('/:id', addressController.getAddress);

// PATCH /api/v1/addresses/:id - Update address
router.patch('/:id',
    validate('updateAddress'),
    addressController.updateAddress
);

// DELETE /api/v1/addresses/:id - Delete address
router.delete('/:id', addressController.deleteAddress);

// PATCH /api/v1/addresses/:id/primary - Set as primary address
router.patch('/:id/primary', addressController.setPrimaryAddress);

module.exports = router;
