// src/services/SmartPlugSimulatorService.js
// ─────────────────────────────────────────────────────────────────────────────
// Generates realistic wattage telemetry for simulated smart plugs.
// Production swap point: replace `readPlug()` implementation with a real
// vendor API call (Tasmota local HTTP, Shelly Cloud, TP-Link Kasa, Tuya).
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Category-specific wattage profiles.
 * Each entry: { base, variance, spikeChance, spikeMult }
 *   base       — typical operating wattage
 *   variance   — ±% natural fluctuation around base
 *   spikeChance— probability (0–1) of a spike on any given reading
 *   spikeMult  — multiplier applied during a spike (2–5×)
 */
const CATEGORY_PROFILES = {
  cooling:       { base: 1500, variance: 0.15, spikeChance: 0.03, spikeMult: 2.2 },
  heating:       { base: 2000, variance: 0.10, spikeChance: 0.02, spikeMult: 1.8 },
  lighting:      { base: 60,   variance: 0.05, spikeChance: 0.01, spikeMult: 3.0 },
  entertainment: { base: 150,  variance: 0.10, spikeChance: 0.02, spikeMult: 2.0 },
  kitchen:       { base: 1200, variance: 0.20, spikeChance: 0.05, spikeMult: 2.5 },
  laundry:       { base: 500,  variance: 0.25, spikeChance: 0.04, spikeMult: 3.0 },
  cleaning:      { base: 800,  variance: 0.20, spikeChance: 0.03, spikeMult: 2.0 },
  computing:     { base: 200,  variance: 0.15, spikeChance: 0.02, spikeMult: 2.5 },
  charging:      { base: 20,   variance: 0.08, spikeChance: 0.01, spikeMult: 2.0 },
  other:         { base: 100,  variance: 0.20, spikeChance: 0.03, spikeMult: 2.5 },
};

const DEFAULT_PROFILE = CATEGORY_PROFILES.other;

// Indian standard voltage and power-factor ranges
const VOLTAGE_BASE   = 230; // V
const VOLTAGE_VARY   = 10;  // ±10V fluctuation
const POWER_FACTOR   = 0.92; // typical for household loads

/**
 * Determines the profile for a plug.
 * @param {object} plug - SmartPlug document
 * @param {object|null} appliance - Linked Appliance document (may be null)
 */
function _getProfile(plug, appliance) {
  if (appliance && CATEGORY_PROFILES[appliance.category]) {
    const cat  = CATEGORY_PROFILES[appliance.category];
    // Respect actual rated wattage if available
    const base = appliance.wattage > 0 ? appliance.wattage : cat.base;
    return { ...cat, base };
  }
  if (plug.baselineWattage > 0) {
    return { ...DEFAULT_PROFILE, base: plug.baselineWattage };
  }
  return DEFAULT_PROFILE;
}

/**
 * Generate one telemetry reading for a plug.
 *
 * @param {object} plug - SmartPlug document
 * @param {object|null} appliance - Linked Appliance document (may be null)
 * @param {{ wattageOverride?: number, forceSpike?: boolean }} opts
 * @returns {{ wattage, voltage, current, powerFactor, isSpike }}
 */
function readPlug(plug, appliance = null, opts = {}) {
  // ── PRODUCTION SWAP POINT ─────────────────────────────────────────────────
  // Replace the body of this function with a real vendor API call:
  //
  //   Tasmota (local HTTP):
  //     const r = await axios.get(`http://${plug.connectionConfig.ipAddress}/cm?cmnd=Status%2010`);
  //     const power = r.data.StatusSNS.ENERGY.Power;
  //     return { wattage: power, voltage: r.data.StatusSNS.ENERGY.Voltage, ... };
  //
  //   Shelly (cloud):
  //     const r = await axios.get(`https://shelly-84-eu.shelly.cloud/device/status`,
  //       { params: { id: plug.connectionConfig.cloudDeviceId, auth_key: process.env.SHELLY_AUTH_KEY } });
  //     const power = r.data.data.device_status['switch:0'].apower;
  //     return { wattage: power, ... };
  //
  //   TP-Link Kasa / Tuya — similar pattern with their SDKs.
  // ─────────────────────────────────────────────────────────────────────────

  const profile = _getProfile(plug, appliance);

  // Allow override wattage for testing/demo
  if (opts.wattageOverride != null) {
    const w = opts.wattageOverride;
    const v = VOLTAGE_BASE + _rand(-VOLTAGE_VARY, VOLTAGE_VARY);
    return {
      wattage:     Math.max(0, _round(w, 1)),
      voltage:     _round(v, 1),
      current:     _round(w / v, 3),
      powerFactor: POWER_FACTOR,
      isSpike:     w > profile.base * 1.5,
    };
  }

  // Natural fluctuation
  const variance = profile.base * profile.variance;
  let wattage    = profile.base + _rand(-variance, variance);

  // Random spike
  const isSpike = opts.forceSpike || Math.random() < profile.spikeChance;
  if (isSpike) {
    const mult  = profile.spikeMult * (0.8 + Math.random() * 0.4); // ±20% on mult
    wattage    *= mult;
  }

  wattage = Math.max(0, _round(wattage, 1));
  const voltage = VOLTAGE_BASE + _rand(-VOLTAGE_VARY, VOLTAGE_VARY);
  const current = _round(wattage / voltage, 3);

  return {
    wattage,
    voltage:     _round(voltage, 1),
    current,
    powerFactor: POWER_FACTOR,
    isSpike,
  };
}

// ── Helpers ───────────────────────────────────────────────────────────────────
function _rand(min, max) {
  return Math.random() * (max - min) + min;
}
function _round(n, dp) {
  const f = Math.pow(10, dp);
  return Math.round(n * f) / f;
}

module.exports = { readPlug };
