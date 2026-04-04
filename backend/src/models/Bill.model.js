// src/models/Bill.model.js
// Separate bill model for better data organization

const mongoose = require('mongoose');

const billSchema = new mongoose.Schema(
    {
        // Reference to the user who owns this bill
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true,
            index: true,
        },
        
        // Bill identification
        billNumber: {
            type: String,
            trim: true,
            maxlength: [100, 'Bill number too long'],
        },
        consumerNumber: {
            type: String,
            trim: true,
            maxlength: [50, 'Consumer number too long'],
        },
        billerId: {
            type: String,
            trim: true,
            maxlength: [50, 'Biller ID too long'],
        },
        
        // Bill source and status
        source: {
            type: String,
            required: [true, 'Bill source is required'],
            enum: {
                values: ['ocr', 'bbps', 'manual'],
                message: '{VALUE} is not a valid bill source'
            },
            default: 'manual',
        },
        status: {
            type: String,
            enum: {
                values: ['UNPAID', 'PAID', 'PARTIALLY_PAID', 'OVERDUE'],
                message: '{VALUE} is not a valid bill status'
            },
            default: 'UNPAID',
        },
        
        // Financial details
        amount: {
            type: Number,
            min: [0, 'Amount cannot be negative'],
            required: [true, 'Amount is required'],
        },
        grossAmount: {
            type: Number,
            min: [0, 'Gross amount cannot be negative'],
        },
        subsidy: {
            type: Number,
            min: [0, 'Subsidy cannot be negative'],
            default: 0,
        },
        
        // Consumption details
        units: {
            type: Number,
            min: [0, 'Units cannot be negative'],
            required: [true, 'Units consumed is required'],
        },
        
        // Billing period
        periodStart: {
            type: Date,
            required: [true, 'Period start date is required'],
        },
        periodEnd: {
            type: Date,
            required: [true, 'Period end date is required'],
            validate: {
                validator: function(v) {
                    return v > this.periodStart;
                },
                message: 'Period end date must be after period start date'
            }
        },
        dueDate: {
            type: Date,
            required: [true, 'Due date is required'],
            validate: {
                validator: function(v) {
                    return v > this.periodEnd;
                },
                message: 'Due date must be after period end date'
            }
        },
        
        // Additional data
        rawText: {
            type: String,
            maxlength: [10000, 'Raw text too long'],
        },
        imageBase64: {
            type: String,
            maxlength: [1048576, 'Image data too large'], // ~1MB limit
        },
        
        // Processing metadata
        ocrConfidence: {
            type: Number,
            min: [0, 'Confidence cannot be negative'],
            max: [1, 'Confidence cannot exceed 1'],
        },
        isVerified: {
            type: Boolean,
            default: false,
        },
        verifiedAt: {
            type: Date,
        },
        
        // Payment tracking
        paidAt: {
            type: Date,
        },
        paymentMethod: {
            type: String,
            enum: {
                values: ['online', 'cash', 'cheque', 'auto_debit'],
                message: '{VALUE} is not a valid payment method'
            },
        },
        
        // Metadata
        isActive: {
            type: Boolean,
            default: true,
        },
        createdAt: {
            type: Date,
            default: Date.now,
        },
        lastUpdated: {
            type: Date,
            default: Date.now,
        },
    },
    {
        timestamps: true,
        toJSON: { virtuals: true },
        toObject: { virtuals: true },
    }
);

// Indexes for better query performance
billSchema.index({ userId: 1, periodStart: -1 });
billSchema.index({ userId: 1, status: 1 });
billSchema.index({ userId: 1, source: 1 });
billSchema.index({ dueDate: 1 });
billSchema.index({ consumerNumber: 1 });

// Virtual for billing period in days
billSchema.virtual('billingPeriodDays').get(function() {
    if (!this.periodStart || !this.periodEnd) return 0;
    return Math.ceil((this.periodEnd - this.periodStart) / (1000 * 60 * 60 * 24));
});

// Virtual for days until due
billSchema.virtual('daysUntilDue').get(function() {
    if (!this.dueDate) return 0;
    return Math.ceil((this.dueDate - new Date()) / (1000 * 60 * 60 * 24));
});

// Virtual for is overdue
billSchema.virtual('isOverdue').get(function() {
    return this.dueDate && new Date() > this.dueDate && this.status !== 'PAID';
});

// Virtual for average daily consumption
billSchema.virtual('averageDailyConsumption').get(function() {
    if (!this.units || !this.billingPeriodDays) return 0;
    return this.units / this.billingPeriodDays;
});

// Pre-save middleware to update lastUpdated
billSchema.pre('save', function(next) {
    this.lastUpdated = new Date();
    
    // Auto-set paidAt when status changes to PAID
    if (this.isModified('status') && this.status === 'PAID' && !this.paidAt) {
        this.paidAt = new Date();
    }
    
    next();
});

// Static method to get user's latest bill
billSchema.statics.getLatestByUser = function(userId) {
    return this.findOne({ userId, isActive: true })
        .sort({ periodEnd: -1 });
};

// Static method to get user's bills by date range
billSchema.statics.getByDateRange = function(userId, startDate, endDate) {
    return this.find({
        userId,
        periodStart: { $gte: startDate },
        periodEnd: { $lte: endDate },
        isActive: true,
    }).sort({ periodStart: -1 });
};

// Static method to get consumption statistics
billSchema.statics.getConsumptionStats = function(userId, months = 12) {
    const startDate = new Date();
    startDate.setMonth(startDate.getMonth() - months);
    
    return this.aggregate([
        {
            $match: {
                userId: new mongoose.Types.ObjectId(userId),
                periodStart: { $gte: startDate },
                isActive: true,
            }
        },
        {
            $group: {
                _id: {
                    year: { $year: '$periodStart' },
                    month: { $month: '$periodStart' },
                },
                totalUnits: { $sum: '$units' },
                totalAmount: { $sum: '$amount' },
                averageDailyUnits: { $avg: '$averageDailyConsumption' },
                billCount: { $sum: 1 },
            }
        },
        { $sort: { '_id.year': -1, '_id.month': -1 } }
    ]);
};

module.exports = mongoose.model('Bill', billSchema);
