// src/jobs/telemetryPoller.js
// ─────────────────────────────────────────────────────────────────────────────
// Background cron job: polls smart plugs every 5 seconds (simulation interval).
// Uses SimulationEngine for stateful, realistic readings.
// Broadcasts results in real-time via WebSocket to connected Flutter clients.
// ─────────────────────────────────────────────────────────────────────────────

const cron              = require('node-cron');
const SmartPlug         = require('../models/SmartPlug.model');
const Appliance         = require('../models/Appliance.model');
const { readPlug }      = require('../services/SimulationEngine');
const { analyseReading } = require('../services/AnomalyDetectionService');
const {
  broadcastReading,
  broadcastAnomaly,
} = require('../websocket/wsServer');

// Concurrency: process N plugs per tick in parallel
const CONCURRENCY = 15;

let _running = false;

/**
 * Process a single plug: generate reading → detect anomaly → persist → broadcast.
 */
async function _processSinglePlug(plug) {
  try {
    const appliance = plug.applianceId
      ? await Appliance.findById(plug.applianceId).lean()
      : null;

    // Generate stateful reading using the SimulationEngine
    const measurement = readPlug(plug, appliance);

    // Anomaly detection, persistence, and FCM notification
    const { reading, isAnomaly, anomalyScore } = await analyseReading({
      plug,
      appliance,
      wattage:     measurement.wattage,
      voltage:     measurement.voltage,
      current:     measurement.current,
      powerFactor: measurement.powerFactor,
    });

    // Real-time broadcast to WebSocket clients
    const plugName      = plug.name;
    const applianceName = appliance?.title || plug.name;

    broadcastReading(reading, plugName, applianceName, {
      deviceState: measurement.state,
      metadata:    measurement.metadata,
    });

    // Extra anomaly broadcast so Flutter can show an in-app banner immediately
    if (isAnomaly) {
      broadcastAnomaly(plug.userId, {
        plugId:        plug.plugId,
        plugName,
        applianceName,
        wattage:       reading.wattage,
        anomalyScore,
        anomalyReason: reading.anomalyReason,
        timestamp:     reading.timestamp,
      });
    }
  } catch (err) {
    console.error(`[TelemetryPoller] Error processing plug ${plug.plugId}:`, err.message);
  }
}

async function _pollTick() {
  if (_running) return;
  _running = true;
  try {
    const plugs = await SmartPlug.find({ isActive: true }).lean();
    if (!plugs.length) { _running = false; return; }

    for (let i = 0; i < plugs.length; i += CONCURRENCY) {
      const batch = plugs.slice(i, i + CONCURRENCY);
      await Promise.all(batch.map(_processSinglePlug));
    }
  } catch (err) {
    console.error('[TelemetryPoller] Fatal tick error:', err.message);
  } finally {
    _running = false;
  }
}

/**
 * Start the telemetry poller.
 * Runs every 5 seconds for responsive real-time updates in the app.
 */
function startTelemetryPoller() {
  // 5-second interval for snappy real-time feel in the demo
  cron.schedule('*/5 * * * * *', _pollTick, {
    scheduled: true,
    timezone:  'Asia/Kolkata',
  });
  console.log('[TelemetryPoller] 🔌 Smart plug telemetry poller started (every 5s)');
}

module.exports = { startTelemetryPoller };
