// src/models/User.model.js
// Refactored User model - now focused on core user profile only

const mongoose = require("mongoose");

// Constants
const CURRENCIES = ["INR", "USD", "EUR", "GBP", "AED"];
const FAMILY_TYPES = ["Just Me", "Small", "Large", "Joint"];
const HOUSE_TYPES = ["Apartment", "Bungalow", "Independent"];

// Household sub-schema (kept as embedded since it's small and closely related)
const HouseholdSchema = new mongoose.Schema(
  {
    peopleCount: {
      type: Number,
      default: 2,
      min: [1, "At least 1 person required"],
      max: [20, "People count seems too high"],
    },
    familyType: {
      type: String,
      enum: {
        values: FAMILY_TYPES,
        message: "{VALUE} is not a valid family type",
      },
      default: null,
    },
    houseType: {
      type: String,
      enum: {
        values: HOUSE_TYPES,
        message: "{VALUE} is not a valid house type",
      },
      default: null,
    },
  },
  { _id: false },
);

// Plan preferences sub-schema
const PlanPreferencesSchema = new mongoose.Schema(
  {
    mainGoals: {
      type: [String],
      default: [],
      validate: {
        validator: function (v) {
          return v.length <= 10;
        },
        message: "Too many goals selected",
      },
    },
    focusArea: {
      type: String,
      default: "ai_decide",
      trim: true,
      maxlength: [50, "Focus area too long"],
    },
  },
  { _id: false },
);

// Location & Address sub-schema
const AddressSchema = new mongoose.Schema(
  {
    state: { type: String, default: null, trim: true },
    city: { type: String, default: null, trim: true },
    discom: { type: String, default: null, trim: true },
    lat: { type: Number, default: null },
    lng: { type: Number, default: null },
  },
  { _id: false },
);

// Device tokens sub-schema
const DeviceTokenSchema = new mongoose.Schema(
  {
    token: {
      type: String,
      required: true,
      index: true,
      maxlength: [500, "Token too long"],
    },
    platform: {
      type: String,
      enum: {
        values: ["android", "ios", "web", "unknown"],
        message: "{VALUE} is not a valid platform",
      },
      default: "unknown",
    },
    lastSeenAt: {
      type: Date,
      default: Date.now,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  { _id: false },
);

// Main User Schema - now focused on core profile
const UserSchema = new mongoose.Schema(
  {
    // Identity (synced with Firebase)
    firebaseUid: {
      type: String,
      required: [true, "Firebase UID is mandatory for user synchronization."],
      unique: true,
      match: [/^[a-zA-Z0-9_-]+$/, "Invalid Firebase UID format"],
    },
    email: {
      type: String,
      required: [true, "Email field is required."],
      unique: true,
      lowercase: true,
      trim: true,
      match: [/^\S+@\S+\.\S+$/, "Please enter a valid email address"],
    },
    name: {
      type: String,
      trim: true,
      minlength: [2, "Name must be at least 2 characters long"],
      maxlength: [100, "Name cannot exceed 100 characters."],
    },
    avatarUrl: {
      type: String,
      default: null,
      trim: true,
      validate: {
        validator: function (v) {
          return !v || /^https?:\/\/.+/.test(v);
        },
        message: "Avatar URL must be a valid HTTP/HTTPS URL",
      },
    },

    // Preferences & Configuration
    address: {
      type: AddressSchema,
      default: () => ({}),
    },
    monthlyBudget: {
      type: Number,
      default: 0,
      min: [0, "Monthly budget cannot be less than 0."],
      max: [1000000, "Monthly budget seems too high"],
    },
    currency: {
      type: String,
      enum: {
        values: CURRENCIES,
        message: "{VALUE} is not a supported currency.",
      },
      default: "INR",
    },

    // Embedded sub-documents (kept small and closely related)
    household: {
      type: HouseholdSchema,
      default: () => ({}),
    },
    planPreferences: {
      type: PlanPreferencesSchema,
      default: () => ({}),
    },
    deviceTokens: {
      type: [DeviceTokenSchema],
      default: [],
      validate: {
        validator: function (v) {
          return v.length <= 10; // Limit device tokens per user
        },
        message: "Too many devices registered",
      },
    },

    // Application State
    onboardingCompleted: {
      type: Boolean,
      default: false,
    },

    // Streak / Check-in tracking
    streak: {
      type: Number,
      default: 0,
      min: [0, "Streak cannot be negative"],
    },
    lastCheckIn: {
      type: Date,
      default: null,
    },
    longestStreak: {
      type: Number,
      default: 0,
      min: [0, "Longest streak cannot be negative"],
    },

    // Active AI Plan
    activePlan: {
      type: mongoose.Schema.Types.Mixed,
      default: null,
    },

    // Daily Heatmap: { "YYYY-MM-DD": 0|1|2|3 }
    // Sparse map; only days with recorded activity are present.
    // intensity: 0=none, 1=low, 2=medium, 3=high
    dailyHeatmap: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },

    // Subscription and tier management
    subscriptionTier: {
      type: String,
      enum: {
        values: ["free", "premium", "enterprise"],
        message: "{VALUE} is not a valid subscription tier",
      },
      default: "free",
    },
    subscriptionExpiresAt: {
      type: Date,
    },

    // Account status
    isActive: {
      type: Boolean,
      default: true,
    },
    isVerified: {
      type: Boolean,
      default: false,
    },
    lastLoginAt: {
      type: Date,
    },

    // Privacy settings
    dataSharingConsent: {
      type: Boolean,
      default: false,
    },
    marketingConsent: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
    minimize: false,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  },
);

// Indexes for better performance
UserSchema.index({ subscriptionTier: 1 });
UserSchema.index({ isActive: 1, isVerified: 1 });
UserSchema.index({ createdAt: -1 });

// Virtuals
UserSchema.virtual("isPremium").get(function () {
  return (
    this.subscriptionTier === "premium" ||
    this.subscriptionTier === "enterprise"
  );
});

UserSchema.virtual("isSubscriptionActive").get(function () {
  return !this.subscriptionExpiresAt || this.subscriptionExpiresAt > new Date();
});

// Pre-save middleware
UserSchema.pre("save", function () {
  // Update last login time if modified
  if (this.isModified("lastLoginAt") && this.lastLoginAt) {
    this.lastLoginAt = new Date();
  }

  // Clean up inactive device tokens
  if (this.isModified("deviceTokens")) {
    this.deviceTokens = this.deviceTokens.filter((token) => token.isActive);
  }
});

// Static methods
UserSchema.statics.findByFirebaseUid = function (firebaseUid) {
  return this.findOne({ firebaseUid, isActive: true });
};

UserSchema.statics.findByEmail = function (email) {
  return this.findOne({ email: email.toLowerCase(), isActive: true });
};

UserSchema.statics.getPremiumUsers = function () {
  return this.find({
    subscriptionTier: { $in: ["premium", "enterprise"] },
    isActive: true,
  });
};

// Instance methods
UserSchema.methods.addDeviceToken = function (token, platform = "unknown") {
  // Remove existing token for this device
  this.deviceTokens = this.deviceTokens.filter((dt) => dt.token !== token);

  // Add new token
  this.deviceTokens.push({
    token,
    platform,
    lastSeenAt: new Date(),
    isActive: true,
  });

  // Keep only last 5 active tokens
  this.deviceTokens = this.deviceTokens
    .sort((a, b) => b.lastSeenAt - a.lastSeenAt)
    .slice(0, 5);

  return this.save();
};

UserSchema.methods.removeDeviceToken = function (token) {
  this.deviceTokens = this.deviceTokens.filter((dt) => dt.token !== token);
  return this.save();
};

UserSchema.methods.updateLastLogin = function () {
  this.lastLoginAt = new Date();
  return this.save();
};

// JSON serialization
UserSchema.set("toJSON", {
  virtuals: true,
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    // Remove sensitive data
    delete ret.deviceTokens;
    return ret;
  },
});

module.exports = mongoose.model("User", UserSchema);
