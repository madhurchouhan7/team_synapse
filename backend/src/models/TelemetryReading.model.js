// src/models/TelemetryReading.model.js
// Time-series telemetry readings ingested from smart plugs.
// Includes a 90-day TTL index for automatic data retention management.

const mongoose = require('mongoose');

const TelemetryReadingSchema = new mongoose.Schema(
  {
    // References
    plugId: {
      type: String,
      required: true,
      index: true,
    },
    applianceId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Appliance',
      default: null,
      index: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },

    // ── Electrical measurements ──────────────────────────────────────────────
    wattage: {
      type: Number,
      required: true,
      min: 0,
    },
    voltage: {
      type: Number,
      default: null, // ~230V AC for India
    },
    current: {
      type: Number,
      default: null, // Amperes
    },
    powerFactor: {
      type: Number,
      default: null, // 0.0 – 1.0
    },

    // ── Anomaly metadata ─────────────────────────────────────────────────────
    isAnomaly: {
      type: Boolean,
      default: false,
      index: true,
    },
    anomalyScore: {
      type: Number,
      default: null, // Z-score value
    },
    anomalyReason: {
      type: String,
      default: null, // Human-readable explanation
    },

    // ── Reading timestamp ────────────────────────────────────────────────────
    // We keep a dedicated `timestamp` field (vs relying on createdAt) so that
    // external systems or backfills can supply the correct measurement time.
    timestamp: {
      type: Date,
      required: true,
      default: Date.now,
      index: true,
    },
  },
  {
    // Disable auto `createdAt`/`updatedAt` to avoid redundancy with `timestamp`
    timestamps: false,
  },
);

// ── Compound indexes for efficient dashboard queries ─────────────────────────
TelemetryReadingSchema.index({ plugId: 1, timestamp: -1 });
TelemetryReadingSchema.index({ userId: 1, isAnomaly: 1, timestamp: -1 });
TelemetryReadingSchema.index({ applianceId: 1, timestamp: -1 });

// ── TTL index: auto-delete readings older than 90 days ───────────────────────
TelemetryReadingSchema.index(
  { timestamp: 1 },
  { expireAfterSeconds: 60 * 60 * 24 * 90 }, // 90 days
);

module.exports = mongoose.model('TelemetryReading', TelemetryReadingSchema);
