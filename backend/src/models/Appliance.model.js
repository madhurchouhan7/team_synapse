// src/models/Appliance.model.js
// Separate appliance model for better data organization

const mongoose = require("mongoose");

const applianceSchema = new mongoose.Schema(
  {
    // Reference to the user who owns this appliance
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },

    // Appliance identification
    applianceId: {
      type: String,
      required: [true, "Appliance ID is required"],
      trim: true,
    },
    title: {
      type: String,
      required: [true, "Appliance name is required"],
      trim: true,
      maxlength: [100, "Appliance name too long"],
    },
    category: {
      type: String,
      required: [true, "Category is required"],
      trim: true,
      enum: {
        values: [
          "cooling",
          "heating",
          "lighting",
          "entertainment",
          "kitchen",
          "laundry",
          "cleaning",
          "computing",
          "charging",
          "other",
        ],
        message: "{VALUE} is not a valid category",
      },
    },

    // Appliance specifications
    wattage: {
      type: Number,
      min: [0, "Wattage cannot be negative"],
      max: [10000, "Wattage seems too high"],
    },
    starRating: {
      type: String,
      trim: true,
      enum: {
        values: [
          "1",
          "2",
          "3",
          "4",
          "5",
          "BEE 5 Star",
          "BEE 4 Star",
          "BEE 3 Star",
          "BEE 2 Star",
          "BEE 1 Star",
        ],
        message: "{VALUE} is not a valid star rating",
      },
    },
    brand: {
      type: String,
      trim: true,
      maxlength: [50, "Brand name too long"],
    },
    model: {
      type: String,
      trim: true,
      maxlength: [50, "Model name too long"],
    },

    // Usage patterns
    usageHoursPerDay: {
      type: Number,
      min: [0, "Usage hours cannot be negative"],
      max: [24, "Usage hours cannot exceed 24"],
      default: 0,
    },
    usageLevel: {
      type: String,
      required: [true, "Usage level is required"],
      enum: {
        values: ["Low", "Medium", "High"],
        message: "{VALUE} is not a valid usage level",
      },
    },
    count: {
      type: Number,
      min: [1, "Count must be at least 1"],
      max: [100, "Count seems too high"],
      default: 1,
    },

    // Additional configuration
    selectedDropdowns: {
      type: Map,
      of: String,
      default: {},
    },
    svgPath: {
      type: String,
      trim: true,
    },

    // Metadata
    isActive: {
      type: Boolean,
      default: true,
    },
    addedAt: {
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
    optimisticConcurrency: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  },
);

// Indexes for better query performance
applianceSchema.index({ userId: 1, isActive: 1 });
applianceSchema.index({ userId: 1, category: 1 });
applianceSchema.index({ userId: 1, usageLevel: 1 });
applianceSchema.index({ userId: 1, isActive: 1, __v: 1 });

// Virtual for daily energy consumption (kWh)
applianceSchema.virtual("dailyConsumption").get(function () {
  if (!this.wattage || !this.usageHoursPerDay) return 0;
  return (this.wattage * this.usageHoursPerDay * this.count) / 1000; // Convert to kWh
});

// Virtual for monthly energy consumption (kWh)
applianceSchema.virtual("monthlyConsumption").get(function () {
  return this.dailyConsumption * 30;
});

// Pre-save middleware to update lastUpdated
applianceSchema.pre("save", function (next) {
  this.lastUpdated = new Date();
  next();
});

// Static method to get user's appliances by category
applianceSchema.statics.getByCategory = function (userId, category) {
  return this.find({ userId, category, isActive: true });
};

// Static method to get user's total consumption
applianceSchema.statics.getTotalConsumption = function (userId) {
  return this.aggregate([
    { $match: { userId: new mongoose.Types.ObjectId(userId), isActive: true } },
    {
      $group: {
        _id: null,
        totalDailyConsumption: {
          $sum: {
            $multiply: ["$wattage", "$usageHoursPerDay", "$count", 0.001],
          },
        },
        totalAppliances: { $sum: "$count" },
      },
    },
  ]);
};

module.exports = mongoose.model("Appliance", applianceSchema);
