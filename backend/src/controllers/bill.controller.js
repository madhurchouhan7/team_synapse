// src/controllers/bill.controller.js
// Controller for managing user bills

const Bill = require('../models/Bill.model');
const { sendSuccess } = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');
const { asyncHandler } = require('../middleware/errorHandler');

// ─── POST /api/v1/bills ─────────────────────────────────────────────────────
exports.createBill = asyncHandler(async (req, res, _next) => {
    const billData = {
        ...req.body,
        userId: req.user._id,
        source: req.body.source || 'manual',
    };
    
    // Handle date conversions
    if (billData.dueDate && typeof billData.dueDate === 'string') {
        billData.dueDate = new Date(billData.dueDate);
    }
    if (billData.periodStart && typeof billData.periodStart === 'string') {
        billData.periodStart = new Date(billData.periodStart);
    }
    if (billData.periodEnd && typeof billData.periodEnd === 'string') {
        billData.periodEnd = new Date(billData.periodEnd);
    }
    
    // Handle amount aliases
    billData.amount = billData.amount || billData.netPayable || billData.amountExact || 0;
    billData.subsidy = billData.subsidy || billData.subsidyAmount || 0;
    
    const bill = await Bill.create(billData);
    
    sendSuccess(res, 201, 'Bill created successfully.', bill);
});

// ─── GET /api/v1/bills ─────────────────────────────────────────────────────
exports.getBills = asyncHandler(async (req, res, _next) => {
    const { status, source, page = 1, limit = 10, startDate, endDate } = req.query;
    
    // Build filter
    const filter = { 
        userId: req.user._id, 
        isActive: true 
    };
    
    if (status) filter.status = status;
    if (source) filter.source = source;
    if (startDate || endDate) {
        filter.periodStart = {};
        if (startDate) filter.periodStart.$gte = new Date(startDate);
        if (endDate) filter.periodStart.$lte = new Date(endDate);
    }
    
    const skip = (page - 1) * limit;
    
    const [bills, total] = await Promise.all([
        Bill.find(filter)
            .sort({ periodEnd: -1 })
            .skip(skip)
            .limit(parseInt(limit)),
        Bill.countDocuments(filter)
    ]);
    
    sendSuccess(res, 200, 'Bills fetched successfully.', {
        bills,
        pagination: {
            page: parseInt(page),
            limit: parseInt(limit),
            total,
            pages: Math.ceil(total / limit)
        }
    });
});

// ─── GET /api/v1/bills/:id ─────────────────────────────────────────────────────
exports.getBill = asyncHandler(async (req, res, _next) => {
    const bill = await Bill.findOne({ 
        _id: req.params.id, 
        userId: req.user._id, 
        isActive: true 
    });
    
    if (!bill) {
        throw new ApiError(404, 'Bill not found.');
    }
    
    sendSuccess(res, 200, 'Bill fetched successfully.', bill);
});

// ─── PATCH /api/v1/bills/:id ─────────────────────────────────────────────────────
exports.updateBill = asyncHandler(async (req, res, _next) => {
    const updateData = { ...req.body };
    
    // Handle date conversions
    if (updateData.dueDate && typeof updateData.dueDate === 'string') {
        updateData.dueDate = new Date(updateData.dueDate);
    }
    if (updateData.periodStart && typeof updateData.periodStart === 'string') {
        updateData.periodStart = new Date(updateData.periodStart);
    }
    if (updateData.periodEnd && typeof updateData.periodEnd === 'string') {
        updateData.periodEnd = new Date(updateData.periodEnd);
    }
    
    const bill = await Bill.findOneAndUpdate(
        { _id: req.params.id, userId: req.user._id, isActive: true },
        { 
            ...updateData,
            lastUpdated: new Date()
        },
        { returnDocument: 'after', runValidators: true }
    );
    
    if (!bill) {
        throw new ApiError(404, 'Bill not found.');
    }
    
    sendSuccess(res, 200, 'Bill updated successfully.', bill);
});

// ─── DELETE /api/v1/bills/:id ─────────────────────────────────────────────────────
exports.deleteBill = asyncHandler(async (req, res, _next) => {
    const bill = await Bill.findOneAndUpdate(
        { _id: req.params.id, userId: req.user._id, isActive: true },
        { isActive: false },
        { returnDocument: 'after' }
    );
    
    if (!bill) {
        throw new ApiError(404, 'Bill not found.');
    }
    
    sendSuccess(res, 200, 'Bill deleted successfully.');
});

// ─── GET /api/v1/bills/latest ─────────────────────────────────────────────────────
exports.getLatestBill = asyncHandler(async (req, res, _next) => {
    const bill = await Bill.getLatestByUser(req.user._id);
    
    if (!bill) {
        throw new ApiError(404, 'No bills found.');
    }
    
    sendSuccess(res, 200, 'Latest bill fetched successfully.', bill);
});

// ─── GET /api/v1/bills/stats ─────────────────────────────────────────────────────
exports.getBillStats = asyncHandler(async (req, res, _next) => {
    const { months = 12 } = req.query;
    
    const stats = await Bill.getConsumptionStats(req.user._id, parseInt(months));
    
    // Calculate additional metrics
    const totalBills = stats.length;
    const totalUnits = stats.reduce((sum, stat) => sum + stat.totalUnits, 0);
    const totalAmount = stats.reduce((sum, stat) => sum + stat.totalAmount, 0);
    const averageMonthlyUnits = totalBills > 0 ? Math.round(totalUnits / totalBills) : 0;
    const averageMonthlyAmount = totalBills > 0 ? Math.round(totalAmount / totalBills) : 0;
    
    const result = {
        summary: {
            totalBills,
            totalUnits,
            totalAmount,
            averageMonthlyUnits,
            averageMonthlyAmount
        },
        monthlyBreakdown: stats
    };
    
    sendSuccess(res, 200, 'Bill statistics fetched successfully.', result);
});

// ─── PATCH /api/v1/bills/:id/verify ─────────────────────────────────────────────────────
exports.verifyBill = asyncHandler(async (req, res, _next) => {
    const { isVerified, ocrConfidence } = req.body;
    
    const bill = await Bill.findOneAndUpdate(
        { _id: req.params.id, userId: req.user._id, isActive: true },
        { 
            isVerified: isVerified !== undefined ? isVerified : true,
            ocrConfidence: ocrConfidence,
            verifiedAt: isVerified !== false ? new Date() : null,
            lastUpdated: new Date()
        },
        { returnDocument: 'after', runValidators: true }
    );
    
    if (!bill) {
        throw new ApiError(404, 'Bill not found.');
    }
    
    sendSuccess(res, 200, 'Bill verification updated successfully.', bill);
});

// ─── PATCH /api/v1/bills/:id/pay ─────────────────────────────────────────────────────
exports.markBillAsPaid = asyncHandler(async (req, res, _next) => {
    const { paymentMethod } = req.body;
    
    const bill = await Bill.findOneAndUpdate(
        { _id: req.params.id, userId: req.user._id, isActive: true },
        { 
            status: 'PAID',
            paidAt: new Date(),
            paymentMethod: paymentMethod || 'manual',
            lastUpdated: new Date()
        },
        { returnDocument: 'after', runValidators: true }
    );
    
    if (!bill) {
        throw new ApiError(404, 'Bill not found.');
    }
    
    sendSuccess(res, 200, 'Bill marked as paid successfully.', bill);
});
