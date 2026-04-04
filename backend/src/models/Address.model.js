// src/models/Address.model.js
// Separate address model for better data organization

const mongoose = require('mongoose');

const addressSchema = new mongoose.Schema(
    {
        // Reference to the user who owns this address
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true,
            index: true,
        },
        
        // Address details
        state: {
            type: String,
            required: [true, 'State is required'],
            trim: true,
            maxlength: [100, 'State name too long'],
        },
        city: {
            type: String,
            required: [true, 'City is required'],
            trim: true,
            maxlength: [100, 'City name too long'],
        },
        discom: {
            type: String,
            required: [true, 'DISCOM is required'],
            trim: true,
            maxlength: [100, 'DISCOM name too long'],
        },
        
        // Geographic coordinates
        lat: {
            type: Number,
            min: -90,
            max: 90,
            validate: {
                validator: function(v) {
                    return v === null || (v >= -90 && v <= 90);
                },
                message: 'Latitude must be between -90 and 90 degrees'
            }
        },
        lng: {
            type: Number,
            min: -180,
            max: 180,
            validate: {
                validator: function(v) {
                    return v === null || (v >= -180 && v <= 180);
                },
                message: 'Longitude must be between -180 and 180 degrees'
            }
        },
        
        // Address metadata
        isPrimary: {
            type: Boolean,
            default: true,
        },
        isActive: {
            type: Boolean,
            default: true,
        },
    },
    {
        timestamps: true,
        toJSON: { virtuals: true },
        toObject: { virtuals: true },
    }
);

// Indexes for better query performance
addressSchema.index({ userId: 1, isActive: 1 });
addressSchema.index({ state: 1, city: 1 });

// Virtual for formatted address
addressSchema.virtual('fullAddress').get(function() {
    return `${this.city}, ${this.state}`;
});

// Ensure only one primary address per user
addressSchema.pre('save', async function(next) {
    if (this.isPrimary && this.isNew) {
        await this.constructor.updateMany(
            { userId: this.userId, isPrimary: true },
            { isPrimary: false }
        );
    }
    next();
});

module.exports = mongoose.model('Address', addressSchema);
