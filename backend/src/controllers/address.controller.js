// src/controllers/address.controller.js
// Controller for managing user addresses

const Address = require('../models/Address.model');
const { sendSuccess } = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');
const { asyncHandler } = require('../middleware/errorHandler');

// ─── POST /api/v1/addresses ─────────────────────────────────────────────────────
exports.createAddress = asyncHandler(async (req, res, _next) => {
    const { state, city, discom, lat, lng, isPrimary } = req.body;
    
    // Create new address
    const address = await Address.create({
        userId: req.user._id,
        state,
        city,
        discom,
        lat,
        lng,
        isPrimary: isPrimary || false,
    });
    
    sendSuccess(res, 201, 'Address created successfully.', address);
});

// ─── GET /api/v1/addresses ─────────────────────────────────────────────────────
exports.getAddresses = asyncHandler(async (req, res, _next) => {
    const addresses = await Address.find({ 
        userId: req.user._id, 
        isActive: true 
    }).sort({ isPrimary: -1, createdAt: -1 });
    
    sendSuccess(res, 200, 'Addresses fetched successfully.', addresses);
});

// ─── GET /api/v1/addresses/:id ─────────────────────────────────────────────────────
exports.getAddress = asyncHandler(async (req, res, _next) => {
    const address = await Address.findOne({ 
        _id: req.params.id, 
        userId: req.user._id, 
        isActive: true 
    });
    
    if (!address) {
        throw new ApiError(404, 'Address not found.');
    }
    
    sendSuccess(res, 200, 'Address fetched successfully.', address);
});

// ─── PATCH /api/v1/addresses/:id ─────────────────────────────────────────────────────
exports.updateAddress = asyncHandler(async (req, res, _next) => {
    const { state, city, discom, lat, lng, isPrimary } = req.body;
    
    const address = await Address.findOneAndUpdate(
        { _id: req.params.id, userId: req.user._id, isActive: true },
        { 
            state, 
            city, 
            discom, 
            lat, 
            lng, 
            isPrimary,
            lastUpdated: new Date()
        },
        { returnDocument: 'after', runValidators: true }
    );
    
    if (!address) {
        throw new ApiError(404, 'Address not found.');
    }
    
    sendSuccess(res, 200, 'Address updated successfully.', address);
});

// ─── DELETE /api/v1/addresses/:id ─────────────────────────────────────────────────────
exports.deleteAddress = asyncHandler(async (req, res, _next) => {
    const address = await Address.findOneAndUpdate(
        { _id: req.params.id, userId: req.user._id, isActive: true },
        { isActive: false },
        { returnDocument: 'after' }
    );
    
    if (!address) {
        throw new ApiError(404, 'Address not found.');
    }
    
    sendSuccess(res, 200, 'Address deleted successfully.');
});

// ─── PATCH /api/v1/addresses/:id/primary ─────────────────────────────────────────────
exports.setPrimaryAddress = asyncHandler(async (req, res, _next) => {
    // First, unset all primary addresses for this user
    await Address.updateMany(
        { userId: req.user._id, isPrimary: true },
        { isPrimary: false }
    );
    
    // Then set the new primary address
    const address = await Address.findOneAndUpdate(
        { _id: req.params.id, userId: req.user._id, isActive: true },
        { isPrimary: true },
        { returnDocument: 'after' }
    );
    
    if (!address) {
        throw new ApiError(404, 'Address not found.');
    }
    
    sendSuccess(res, 200, 'Primary address set successfully.', address);
});
