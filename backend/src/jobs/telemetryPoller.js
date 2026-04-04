// src/jobs/telemetryPoller.js
// ─────────────────────────────────────────────────────────────────────────────
// Background cron job — polls all active smart plugs every 5 seconds.
//
// Routing logic (per plug):
//   vendor === 'tuya'            → TuyaService.readPlugMetrics()  [REAL hardware]
//   vendor === 'simulator' | *   → SimulationEngine.readPlug()    [simulated]
//
// After reading, every plug goes through the same pipeline:
//   AnomalyDetectionService.analyseReading() → TelemetryReading + SmartPlug update
//   wsServer.broadcastReading() → Flutter WebSocket client
//   wsServer.broadcastAnomaly() → Flutter anomaly banner (if anomaly)
// ─────────────────────────────────────────────────────────────────────────────

const cron               = require('node-cron');
const SmartPlug          = require('../models/SmartPlug.model');
const Appliance          = require('../models/Appliance.model');
const SimulationEngine   = require('../services/SimulationEngine');
const TuyaService        = require('../services/TuyaService');
const { analyseReading } = require('../services/AnomalyDetectionService');
const {
  broadcastReading,
  broadcastAnomaly,
} = require('../websocket/wsServer');

const CONCURRENCY = 15;
let _running = false;

// ── Read one plug ─────────────────────────────────────────────────────────────

/**
 * Obtain a reading for a single plug using the correct backend.
 * @returns {{ wattage, voltage, current, powerFactor, state?, isOnline? }}
 */
async function _readFromSource(plug, appliance) {
  // ── REAL Tuya hardware ─────────────────────────────────────────────────────
  if (plug.vendor === 'tuya' && !plug.isSimulated) {
    const deviceId = plug.connectionConfig?.cloudDeviceId;
    if (!deviceId) {
      throw new Error(`Tuya plug "${plug.name}" has no cloudDeviceId configured.`);
    }

    const metrics = await TuyaService.readPlugMetrics(deviceId);

    // Mark plug online/offline based on what Tuya reports
    if (!metrics.isOnline) {
      await SmartPlug.findByIdAndUpdate(plug._id, { $set: { isOnline: false } });
      return null; // skip processing if device is offline
    }

    return {
      wattage:     metrics.wattage,
      voltage:     metrics.voltage,
      current:     metrics.current,
      powerFactor: metrics.powerFactor,
      state:       metrics.isOn ? 'on' : 'off',
      isOnline:    metrics.isOnline,
      source:      'tuya',
    };
  }

  // ── Simulated plug ─────────────────────────────────────────────────────────
  const measurement = SimulationEngine.readPlug(plug, appliance);
  return { ...measurement, source: 'simulator' };
}

// ── Process one plug per tick ─────────────────────────────────────────────────

async function _processSinglePlug(plug) {
  try {
    const appliance = plug.applianceId
      ? await Appliance.findById(plug.applianceId).lean()
      : null;

    // Get reading from the appropriate source
    const measurement = await _readFromSource(plug, appliance);
    if (!measurement) return; // device offline — skip

    // Anomaly detection + persist + update plug snapshot
    const { reading, isAnomaly, anomalyScore } = await analyseReading({
      plug,
      appliance,
      wattage:     measurement.wattage,
      voltage:     measurement.voltage,
      current:     measurement.current,
      powerFactor: measurement.powerFactor,
    });

    // Real-time WebSocket broadcast
    const plugName      = plug.name;
    const applianceName = appliance?.title || plug.name;

    broadcastReading(reading, plugName, applianceName, {
      deviceState: measurement.state,
      source:      measurement.source,
      metadata:    measurement.metadata || {},
    });

    if (isAnomaly) {
      broadcastAnomaly(plug.userId, {
        plugId:        plug.plugId,
        plugName,
        applianceName,
        wattage:       reading.wattage,
        anomalyScore,
        anomalyReason: reading.anomalyReason,
        timestamp:     reading.timestamp,
        source:        measurement.source,
      });
    }
  } catch (err) {
    console.error(
      `[TelemetryPoller] Error processing plug "${plug.name}" (${plug.vendor}):`,
      err.message,
    );

    // For Tuya plugs: if we consistently get errors, mark offline
    if (plug.vendor === 'tuya') {
      await SmartPlug.findByIdAndUpdate(plug._id, {
        $set: { isOnline: false },
      }).catch(() => {}); // best-effort
    }
  }
}

// ── Main tick ─────────────────────────────────────────────────────────────────

async function _pollTick() {
  if (_running) return;
  _running = true;
  try {
    const plugs = await SmartPlug.find({ isActive: true }).lean();
    if (!plugs.length) { _running = false; return; }

    // Process in batches of CONCURRENCY
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

// ── Start ─────────────────────────────────────────────────────────────────────

function startTelemetryPoller() {
  cron.schedule('*/5 * * * * *', _pollTick, {
    scheduled: true,
    timezone:  'Asia/Kolkata',
  });
  console.log('[TelemetryPoller] 🔌 Telemetry poller started (every 5s). Tuya + Simulator both active.');
}

module.exports = { startTelemetryPoller };
