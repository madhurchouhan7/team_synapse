// src/models/SmartPlug.model.js
// Represents a registered smart plug device linked to a user and optionally an appliance.
// Supports both real vendor plugs (Tasmota, Shelly, TP-Link Kasa) and simulated plugs.

const mongoose = require('mongoose');

const SmartPlugSchema = new mongoose.Schema(
  {
    // Owner
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },

    // Linked appliance (optional — plug can be "unassigned")
    applianceId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Appliance',
      default: null,
    },

    // Plug identity
    plugId: {
      type: String,
      required: true,
      trim: true,
      // e.g. "tasmota-abc123", "shelly-plug-01", "sim-uuid"
    },

    name: {
      type: String,
      required: true,
      trim: true,
      maxlength: [100, 'Plug name too long'],
    },

    // Vendor / integration type
    vendor: {
      type: String,
      enum: {
        values: ['tasmota', 'shelly', 'tplink_kasa', 'tuya', 'simulator', 'webhook', 'other'],
        message: '{VALUE} is not a supported vendor',
      },
      default: 'simulator',
    },

    // Connection details for real plugs (stored but not exposed in API responses)
    connectionConfig: {
      // Tasmota / Shelly — local IP address
      ipAddress: { type: String, default: null, trim: true },
      // TP-Link Kasa / Tuya — cloud account credentials (obfuscated)
      cloudDeviceId: { type: String, default: null, trim: true },
      // Webhook endpoint secret (for incoming Tasmota/Shelly push)
      webhookSecret: { type: String, default: null, trim: true },
    },

    // Whether this plug uses the built-in simulator
    isSimulated: {
      type: Boolean,
      default: true,
    },

    // Last-known operational status
    isOnline: {
      type: Boolean,
      default: false,
    },

    // Location label (e.g. "Living Room", "Kitchen")
    location: {
      type: String,
      trim: true,
      maxlength: [100, 'Location label too long'],
      default: null,
    },

    // Appliance rated wattage — used as anomaly baseline seed
    baselineWattage: {
      type: Number,
      default: 0,
      min: 0,
    },

    // Soft-delete flag
    isActive: {
      type: Boolean,
      default: true,
      index: true,
    },

    // Latest telemetry snapshot (denormalised for fast dashboard reads)
    lastReading: {
      wattage: { type: Number, default: null },
      timestamp: { type: Date, default: null },
      isAnomaly: { type: Boolean, default: false },
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  },
);

// Sparse unique index: one plug-id per user
SmartPlugSchema.index({ userId: 1, plugId: 1 }, { unique: true, sparse: true });
SmartPlugSchema.index({ userId: 1, isActive: 1 });

module.exports = mongoose.model('SmartPlug', SmartPlugSchema);
