// src/services/AnomalyDetectionService.js
// ─────────────────────────────────────────────────────────────────────────────
// Detects abnormal power consumption using a rolling Z-score algorithm.
//
// Algorithm:
//   1. Maintain a rolling window of the last WINDOW_SIZE wattage readings
//      per plug in Redis (fast, persistent across restarts, low memory).
//   2. On each new reading, compute mean and std-dev of the window.
//   3. Z-score = (newReading - mean) / stdDev
//   4. If |Z-score| > ANOMALY_THRESHOLD → flag as anomaly.
//   5. Persist TelemetryReading with anomaly metadata.
//   6. Fire notification via notification.service.js.
// ─────────────────────────────────────────────────────────────────────────────

const { createAndSendNotification } = require('./notification.service');
const TelemetryReading = require('../models/TelemetryReading.model');
const SmartPlug        = require('../models/SmartPlug.model');

// ── Constants ─────────────────────────────────────────────────────────────────
const WINDOW_SIZE        = 24;   // number of readings in rolling baseline
const ANOMALY_THRESHOLD  = 2.5;  // Z-score above which an alert fires
const MIN_WINDOW         = 5;    // minimum readings before anomaly detection starts
const ANOMALY_COOLDOWN_S = 300;  // seconds between repeated alerts for same plug

// ── Redis-backed rolling window helpers ──────────────────────────────────────
let _redis = null;

/**
 * Lazily initialise the Redis client.
 * Falls back to in-memory Map if Redis is unavailable (dev env without Redis).
 */
const _inMemoryStore = new Map(); // fallback

async function _getRedis() {
  if (_redis) return _redis;
  try {
    const Redis = require('ioredis');
    _redis = new Redis(process.env.REDIS_URL || 'redis://localhost:6379', {
      lazyConnect: true,
      enableOfflineQueue: false,
      maxRetriesPerRequest: 1,
    });
    await _redis.ping();
    return _redis;
  } catch (_err) {
    _redis = null;
    return null;
  }
}

function _windowKey(plugId) { return `ws:plug:${plugId}`; }
function _cooldownKey(plugId) { return `ws:cd:${plugId}`; }

/**
 * Append a wattage value to the plug's rolling window and trim to WINDOW_SIZE.
 * @returns {number[]} current window values
 */
async function _appendToWindow(plugId, wattage) {
  const redis = await _getRedis();
  if (redis) {
    try {
      const key = _windowKey(plugId);
      await redis.rpush(key, wattage);
      await redis.ltrim(key, -WINDOW_SIZE, -1);
      const raw = await redis.lrange(key, 0, -1);
      return raw.map(Number);
    } catch (err) {
      _redis = null; // invalidate broken connection and fallback
    }
  }
  // In-memory fallback
  const arr = _inMemoryStore.get(plugId) || [];
  arr.push(wattage);
  if (arr.length > WINDOW_SIZE) arr.shift();
  _inMemoryStore.set(plugId, arr);
  return [...arr];
}

/**
 * Check (and set) anomaly cooldown.
 * @returns {boolean} true if still in cooldown (suppress notification)
 */
async function _isInCooldown(plugId) {
  const redis = await _getRedis();
  if (redis) {
    try {
      const key = _cooldownKey(plugId);
      const exists = await redis.get(key);
      if (exists) return true;
      await redis.set(key, '1', 'EX', ANOMALY_COOLDOWN_S);
      return false;
    } catch (err) {
      _redis = null;
    }
  }
  return false; // no cooldown tracking in memory fallback
}

// ── Statistics ────────────────────────────────────────────────────────────────
function _mean(arr) {
  return arr.reduce((s, v) => s + v, 0) / arr.length;
}

function _stdDev(arr, mean) {
  const variance = arr.reduce((s, v) => s + Math.pow(v - mean, 2), 0) / arr.length;
  return Math.sqrt(variance);
}

// ── Public API ────────────────────────────────────────────────────────────────

/**
 * Analyse a new telemetry reading for a smart plug.
 *
 * @param {object} params
 * @param {object} params.plug            - SmartPlug document
 * @param {object|null} params.appliance  - Linked Appliance document (may be null)
 * @param {number} params.wattage         - Current wattage reading
 * @param {number} params.voltage
 * @param {number} params.current
 * @param {number} params.powerFactor
 *
 * @returns {Promise<{ reading: TelemetryReading, isAnomaly: boolean, anomalyScore: number|null }>}
 */
async function analyseReading({ plug, appliance, wattage, voltage, current, powerFactor }) {
  const window = await _appendToWindow(plug.plugId, wattage);

  let isAnomaly    = false;
  let anomalyScore = null;
  let anomalyReason = null;

  // Only start anomaly detection once we have enough data
  if (window.length >= MIN_WINDOW) {
    const baseline = window.slice(0, -1); // exclude current reading
    if (baseline.length >= 2) {
      const mu  = _mean(baseline);
      const sig = _stdDev(baseline, mu);

      if (sig > 0) {
        anomalyScore = (wattage - mu) / sig;

        // Flag anomaly only on positive spikes and if the absolute increase is meaningful (> 15W)
        if (anomalyScore > ANOMALY_THRESHOLD && (wattage - mu) > 15) {
          isAnomaly     = true;
          const pct     = Math.round(((wattage - mu) / mu) * 100);
          anomalyReason = `Consumption is ${Math.abs(pct)}% higher than the recent baseline (${Math.round(mu)}W avg). Z-score: ${anomalyScore.toFixed(2)}.`;
        }
      }
    }
  }

  // Persist the reading
  const reading = await TelemetryReading.create({
    plugId:        plug.plugId,
    applianceId:   plug.applianceId,
    userId:        plug.userId,
    wattage,
    voltage,
    current,
    powerFactor,
    timestamp:     new Date(),
    isAnomaly,
    anomalyScore,
    anomalyReason,
  });

  // Update plug's latest reading snapshot
  await SmartPlug.findByIdAndUpdate(plug._id, {
    $set: {
      isOnline: true,
      'lastReading.wattage':   wattage,
      'lastReading.timestamp': new Date(),
      'lastReading.isAnomaly': isAnomaly,
    },
  });

  // Fire notification only when anomaly + cooldown not active
  if (isAnomaly) {
    const suppressed = await _isInCooldown(plug.plugId);
    if (!suppressed) {
      const applianceName = appliance?.title || plug.name;
      const watts         = Math.round(wattage);
      await createAndSendNotification(plug.userId, {
        title: `⚡ Abnormal Usage: ${applianceName}`,
        body:  `${applianceName} is drawing ${watts}W — ${anomalyReason}`,
        type:  'high_usage_alert',
        data:  {
          plugId:        plug.plugId,
          plugName:      plug.name,
          applianceName,
          applianceId:   plug.applianceId?.toString() || '',
          wattage:       String(watts),
          anomalyScore:  anomalyScore != null ? anomalyScore.toFixed(2) : '',
          anomalyReason: anomalyReason || '',
        },
      });
    }
  }

  return { reading, isAnomaly, anomalyScore };
}

module.exports = { analyseReading };
