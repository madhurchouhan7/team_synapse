// src/routes/bill.routes.js
// Routes for bill management

const express = require('express');
const router = express.Router();

const authMiddleware = require('../middleware/authMiddleware');
const { validate } = require('../middleware/validation.middleware');
const { rateLimiters } = require('../middleware/rateLimit.middleware');
const billController = require('../controllers/bill.controller');

// Apply auth middleware to all routes
router.use(authMiddleware);

// ─── Bill Routes ─────────────────────────────────────────────────────

// POST /api/v1/bills - Create new bill
router.post('/', 
    rateLimiters.billFetch,
    validate('addBill'), 
    billController.createBill
);

// GET /api/v1/bills - Get all user bills
router.get('/', billController.getBills);

// GET /api/v1/bills/latest - Get latest bill
router.get('/latest', billController.getLatestBill);

// GET /api/v1/bills/stats - Get bill statistics
router.get('/stats', billController.getBillStats);

// GET /api/v1/bills/:id - Get specific bill
router.get('/:id', billController.getBill);

// PATCH /api/v1/bills/:id - Update bill
router.patch('/:id', 
    rateLimiters.billFetch,
    validate('addBill'), 
    billController.updateBill
);

// DELETE /api/v1/bills/:id - Delete bill
router.delete('/:id', 
    rateLimiters.billFetch,
    billController.deleteBill
);

// PATCH /api/v1/bills/:id/verify - Verify bill
router.patch('/:id/verify', billController.verifyBill);

// PATCH /api/v1/bills/:id/pay - Mark bill as paid
router.patch('/:id/pay', billController.markBillAsPaid);

module.exports = router;
