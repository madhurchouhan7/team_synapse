// src/models/Plan.model.js
// Separate plan model for AI-generated efficiency plans

const mongoose = require('mongoose');

const planSchema = new mongoose.Schema(
    {
        // Reference to the user who owns this plan
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true,
            index: true,
        },
        
        // Plan identification
        planType: {
            type: String,
            required: [true, 'Plan type is required'],
            enum: {
                values: ['efficiency', 'savings', 'maintenance', 'custom'],
                message: '{VALUE} is not a valid plan type'
            },
        },
        title: {
            type: String,
            required: [true, 'Plan title is required'],
            trim: true,
            maxlength: [200, 'Plan title too long'],
        },
        
        // Plan status and lifecycle
        status: {
            type: String,
            required: [true, 'Plan status is required'],
            enum: {
                values: ['draft', 'active', 'completed', 'paused', 'expired'],
                message: '{VALUE} is not a valid plan status'
            },
            default: 'draft',
        },
        
        // Plan content (structured AI output)
        summary: {
            type: String,
            required: [true, 'Plan summary is required'],
            maxlength: [1000, 'Summary too long'],
        },
        estimatedCurrentMonthlyCost: {
            type: Number,
            min: [0, 'Cost cannot be negative'],
        },
        estimatedSavingsIfFollowed: {
            units: { type: Number, min: 0 },
            rupees: { type: Number, min: 0 },
            percentage: { type: Number, min: 0, max: 100 },
        },
        efficiencyScore: {
            type: Number,
            min: [0, 'Efficiency score cannot be negative'],
            max: [100, 'Efficiency score cannot exceed 100'],
        },
        
        // Action items
        keyActions: [{
            priority: {
                type: String,
                required: true,
                enum: {
                    values: ['high', 'medium', 'low'],
                    message: '{VALUE} is not a valid priority'
                },
            },
            appliance: {
                type: String,
                required: true,
                trim: true,
            },
            action: {
                type: String,
                required: true,
                trim: true,
            },
            impact: {
                type: String,
                required: true,
                trim: true,
            },
            estimatedSaving: {
                type: String,
                trim: true,
            },
            isCompleted: {
                type: Boolean,
                default: false,
            },
            completedAt: {
                type: Date,
            },
        }],
        
        // Alerts and warnings
        slabAlert: {
            isInDangerZone: { type: Boolean, default: false },
            currentSlab: { type: String, trim: true },
            nextSlabAt: { type: Number },
            unitsToNextSlab: { type: Number },
            warning: { type: String, trim: true },
        },
        
        // Quick tips and recommendations
        quickWins: [{
            type: String,
            trim: true,
        }],
        monthlyTip: {
            type: String,
            trim: true,
            maxlength: [500, 'Monthly tip too long'],
        },
        
        // Plan generation context
        generationContext: {
            userGoal: { type: String, trim: true },
            focusArea: { type: String, trim: true },
            location: { type: String, trim: true },
            weatherContext: { type: String, trim: true },
            applianceCount: { type: Number, min: 0 },
            lastBillAmount: { type: Number, min: 0 },
            lastBillUnits: { type: Number, min: 0 },
        },
        
        // Progress tracking
        progress: {
            totalActions: { type: Number, default: 0 },
            completedActions: { type: Number, default: 0 },
            completionPercentage: { type: Number, default: 0 },
            actualSavings: {
                units: { type: Number, default: 0 },
                rupees: { type: Number, default: 0 },
            },
        },
        
        // Plan timeline
        startDate: {
            type: Date,
            default: Date.now,
        },
        endDate: {
            type: Date,
            validate: {
                validator: function(v) {
                    return !v || v > this.startDate;
                },
                message: 'End date must be after start date'
            }
        },
        
        // Metadata
        isActive: {
            type: Boolean,
            default: true,
        },
        isArchived: {
            type: Boolean,
            default: false,
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
planSchema.index({ userId: 1, status: 1 });
planSchema.index({ userId: 1, planType: 1 });
planSchema.index({ userId: 1, createdAt: -1 });
planSchema.index({ status: 1, isActive: 1 });

// Virtual for plan duration in days
planSchema.virtual('durationDays').get(function() {
    if (!this.endDate) return 0;
    return Math.ceil((this.endDate - this.startDate) / (1000 * 60 * 60 * 24));
});

// Virtual for days remaining
planSchema.virtual('daysRemaining').get(function() {
    if (!this.endDate) return 0;
    return Math.ceil((this.endDate - new Date()) / (1000 * 60 * 60 * 24));
});

// Virtual for is expired
planSchema.virtual('isExpired').get(function() {
    return this.endDate && new Date() > this.endDate;
});

// Pre-save middleware to update progress and timestamps
planSchema.pre('save', function(next) {
    this.lastUpdated = new Date();
    
    // Update progress statistics
    if (this.keyActions && this.keyActions.length > 0) {
        this.progress.totalActions = this.keyActions.length;
        this.progress.completedActions = this.keyActions.filter(action => action.isCompleted).length;
        this.progress.completionPercentage = Math.round((this.progress.completedActions / this.progress.totalActions) * 100);
    }
    
    next();
});

// Static method to get user's active plan
planSchema.statics.getActiveByUser = function(userId) {
    return this.findOne({ 
        userId, 
        status: 'active', 
        isActive: true,
        isArchived: false 
    }).sort({ createdAt: -1 });
};

// Static method to get user's plan history
planSchema.statics.getHistoryByUser = function(userId, limit = 10) {
    return this.find({ 
        userId, 
        isActive: true,
        isArchived: false 
    })
    .sort({ createdAt: -1 })
    .limit(limit);
};

// Static method to get plan statistics
planSchema.statics.getStatsByUser = function(userId) {
    return this.aggregate([
        { $match: { userId: new mongoose.Types.ObjectId(userId), isActive: true } },
        {
            $group: {
                _id: '$status',
                count: { $sum: 1 },
                avgCompletion: { $avg: '$progress.completionPercentage' },
                totalSavings: { $sum: '$progress.actualSavings.rupees' },
            }
        }
    ]);
};

module.exports = mongoose.model('Plan', planSchema);
