// src/services/SimulationEngine.js
// ═══════════════════════════════════════════════════════════════════════════════
// WattSense Realistic Home Appliance Simulation Engine
// ───────────────────────────────────────────────────────────────────────────────
//
// Simulates real-world smart home appliances using state-machine behavioral
// models calibrated to Indian household energy consumption data.
//
// Each appliance runs through a realistic duty cycle:
//   AC        → startup surge → cooling → fan-only → cooling → …
//   Refrigerator → compressor-on → standby → compressor-on (defrost every 8h)
//   Washing Machine → soak → wash → rinse → spin (one-shot lifecycle)
//   Water Heater → heating → thermostat-cut → standby
//   TV/Entertainment → active → standby
//   Lighting → on/dimmed/off  (circadian rhythm based on time of day)
//   Kitchen → burst cooking → idle → burst
//
// The engine also models:
//   • Time-of-day usage patterns (circadian, IST)
//   • Indian grid voltage fluctuation (±10V around 230V)
//   • Startup inrush current / surge wattage
//   • Thermal drift (wattage increases as motor heats up)
//   • Device ageing (older devices consume more → anomaly source)
//   • Configurable scenarios: NORMAL | PEAK_HOUR | NIGHT | FAULT
// ═══════════════════════════════════════════════════════════════════════════════

const EventEmitter = require('events');

// ── Constants ─────────────────────────────────────────────────────────────────
const VOLTAGE_BASE   = 230;  // V  (Indian standard)
const VOLTAGE_VARY   = 12;   // ± V fluctuation
const VOLTAGE_SAG    = 15;   // extra sag during peak hours

// Scenarios
const SCENARIOS = {
  NORMAL:    'normal',
  PEAK_HOUR: 'peak_hour',   // 6-10 PM: AC + kitchen combo
  NIGHT:     'night',        // 10 PM-6 AM: low usage
  FAULT:     'fault',        // force anomalous readings on all plugs
  VACATION:  'vacation',     // only fridge + lighting on minimal
};

// ── Per-category behavioral models ────────────────────────────────────────────
// duty_cycle: fraction of time compressor/element is ON
// states: finite state machine definition
// transitions: { fromState → { next: state, minSec: n, maxSec: n } }
// power: { state: { base, variance, inrush } }

const APPLIANCE_MODELS = {

  // ── Air Conditioner (1.5-ton inverter, 5-star) ────────────────────────────
  cooling: {
    initialState: 'off',
    states: ['startup', 'cooling', 'fan_only', 'off'],
    transitions: {
      startup:  { next: 'cooling',   minSec: 4,   maxSec: 8   },
      cooling:  { next: 'fan_only',  minSec: 600, maxSec: 1200 }, // 10-20 min
      fan_only: { next: 'cooling',   minSec: 180, maxSec: 360  }, // 3-6 min
      off:      { next: 'startup',   minSec: 0,   maxSec: 0    }, // manual
    },
    power: {
      startup:  { base: 2300, variance: 150, inrush: 1.4 }, // inrush surge
      cooling:  { base: 1350, variance: 80               },
      fan_only: { base: 85,   variance: 10               },
      off:      { base: 0,    variance: 0                },
    },
    voltage:     { base: 230, vary: 12 },
    powerFactor: { normal: 0.88, startup: 0.72 },
    activeHours: [8, 22],   // IST hours when AC is likely ON
    peakMultiplier: 1.15,    // hotter afternoon → compressor works harder
  },

  // ── Refrigerator (200-250L, 4-star inverter BEE) ──────────────────────────
  kitchen_fridge: {
    initialState: 'compressor_on',
    states: ['compressor_on', 'standby', 'defrost'],
    transitions: {
      compressor_on: { next: 'standby',       minSec: 90,   maxSec: 240  },
      standby:       { next: 'compressor_on', minSec: 240,  maxSec: 480  },
      defrost:       { next: 'compressor_on', minSec: 1200, maxSec: 1800 }, // 20-30 min defrost
    },
    power: {
      compressor_on: { base: 155, variance: 20 },
      standby:       { base: 4,   variance: 1  },
      defrost:       { base: 200, variance: 15 }, // defrost heater
    },
    voltage:     { base: 230, vary: 8 },
    powerFactor: { normal: 0.85 },
    // Defrost every ~8h — tracked via defrostTimer in state
    defrostIntervalMs: 8 * 60 * 60 * 1000,
    activeHours: [0, 24], // always on
    // No activeHours cutoff — fridge never turns off
  },

  // ── Washing Machine (front-load, 7 kg) ────────────────────────────────────
  laundry: {
    initialState: 'off',
    states: ['fill', 'wash', 'rinse', 'spin', 'done', 'off'],
    transitions: {
      fill:  { next: 'wash',  minSec: 60,  maxSec: 90  },
      wash:  { next: 'rinse', minSec: 840, maxSec: 1200 }, // 14-20 min
      rinse: { next: 'spin',  minSec: 360, maxSec: 480  },
      spin:  { next: 'done',  minSec: 480, maxSec: 720  },
      done:  { next: 'off',   minSec: 10,  maxSec: 20   },
      off:   { next: 'fill',  minSec: 0,   maxSec: 0    },
    },
    power: {
      fill:  { base: 50,   variance: 10 },             // just water valve
      wash:  { base: 400,  variance: 30, hasHeater: true }, // +1500W if hot wash
      rinse: { base: 200,  variance: 20 },
      spin:  { base: 480,  variance: 40 },             // motor at high speed
      done:  { base: 15,   variance: 5  },             // beeping + display
      off:   { base: 0,    variance: 0  },
    },
    voltage:     { base: 230, vary: 10 },
    powerFactor: { normal: 0.82, spin: 0.95 },
    activeHours: [7, 12], // typically used morning
    runOnce: true,        // completes one cycle then goes back to 'off'
  },

  // ── Water Heater / Geyser (2000W, BEE 5-star) ─────────────────────────────
  heating: {
    initialState: 'off',
    states: ['heating', 'thermostat_hold', 'standby', 'off'],
    transitions: {
      heating:         { next: 'thermostat_hold', minSec: 600,  maxSec: 1200 },
      thermostat_hold: { next: 'heating',         minSec: 900,  maxSec: 1800 },
      standby:         { next: 'off',             minSec: 600,  maxSec: 900  },
      off:             { next: 'heating',         minSec: 0,    maxSec: 0    },
    },
    power: {
      heating:         { base: 2000, variance: 50  },
      thermostat_hold: { base: 8,    variance: 2   }, // just thermostat relay leakage
      standby:         { base: 15,   variance: 5   },
      off:             { base: 0,    variance: 0   },
    },
    voltage:     { base: 230, vary: 5 },
    powerFactor: { normal: 0.99 }, // resistive load
    activeHours: [5, 10], // morning usage (IST)
  },

  // ── TV / Entertainment (43" QLED, ~120W) ──────────────────────────────────
  entertainment: {
    initialState: 'active',
    states: ['active', 'standby'],
    transitions: {
      active:  { next: 'standby', minSec: 1800, maxSec: 7200 }, // 30min-2h
      standby: { next: 'active',  minSec: 300,  maxSec: 3600 },
    },
    power: {
      active:  { base: 120, variance: 15 },
      standby: { base: 0.5, variance: 0.2 },
    },
    voltage:     { base: 230, vary: 8 },
    powerFactor: { normal: 0.95 },
    activeHours: [17, 24], // evening + night
  },

  // ── LED Lighting (household, 6 bulbs × 9W) ───────────────────────────────
  lighting: {
    initialState: 'on',
    states: ['on', 'dim', 'off'],
    transitions: {
      on:  { next: 'dim', minSec: 3600, maxSec: 7200 },
      dim: { next: 'off', minSec: 1800, maxSec: 3600 },
      off: { next: 'on',  minSec: 3600, maxSec: 14400 },
    },
    power: {
      on:  { base: 54, variance: 4 },  // 6 × 9W
      dim: { base: 27, variance: 2 },  // 3 bulbs
      off: { base: 0,  variance: 0 },
    },
    voltage:     { base: 230, vary: 15 },
    powerFactor: { normal: 0.9 },
    activeHours: [18, 24, 0, 7], // dusk-dawn active
  },

  // ── Microwave / Kitchen appliance (900W) ────────────────────────────────
  kitchen: {
    initialState: 'idle',
    states: ['idle', 'cooking', 'standby'],
    transitions: {
      idle:     { next: 'cooking',  minSec: 1800, maxSec: 7200 }, // random cooking
      cooking:  { next: 'standby', minSec: 60,   maxSec: 600  }, // 1-10 min burst
      standby:  { next: 'idle',    minSec: 300,  maxSec: 900  },
    },
    power: {
      idle:     { base: 3,   variance: 1   },
      cooking:  { base: 900, variance: 50  }, // full blast
      standby:  { base: 2,   variance: 0.5 },
    },
    voltage:     { base: 230, vary: 10 },
    powerFactor: { normal: 0.97 },
    activeHours: [6, 10, 12, 15, 18, 22], // meal times
  },

  // ── General / Computing (laptop + peripherals) ────────────────────────────
  computing: {
    initialState: 'active',
    states: ['active', 'idle', 'sleep'],
    transitions: {
      active: { next: 'idle',   minSec: 1200, maxSec: 3600 },
      idle:   { next: 'active', minSec: 600,  maxSec: 1800 },
      sleep:  { next: 'idle',   minSec: 300,  maxSec: 900  },
    },
    power: {
      active: { base: 180, variance: 30 }, // gaming/heavy workload
      idle:   { base: 60,  variance: 10 },
      sleep:  { base: 5,   variance: 1  },
    },
    voltage:     { base: 230, vary: 8 },
    powerFactor: { normal: 0.92 },
    activeHours: [9, 23],
  },

  // ── Charging (phone/tablet/laptop USB) ───────────────────────────────────
  charging: {
    initialState: 'fast_charge',
    states: ['fast_charge', 'trickle', 'full'],
    transitions: {
      fast_charge: { next: 'trickle', minSec: 1800, maxSec: 3600 },
      trickle:     { next: 'full',    minSec: 1200, maxSec: 2400 },
      full:        { next: 'fast_charge', minSec: 7200, maxSec: 14400 }, // discharge & recharge
    },
    power: {
      fast_charge: { base: 25, variance: 3 },
      trickle:     { base: 8,  variance: 2 },
      full:        { base: 1,  variance: 0.5 },
    },
    voltage:     { base: 5, vary: 0.5 }, // USB-C
    powerFactor: { normal: 0.85 },
    activeHours: [21, 7], // overnight charging
  },

  // ── Default/Other ──────────────────────────────────────────────────────────
  other: {
    initialState: 'on',
    states: ['on', 'off'],
    transitions: {
      on:  { next: 'off', minSec: 1800, maxSec: 7200 },
      off: { next: 'on',  minSec: 600,  maxSec: 3600 },
    },
    power: {
      on:  { base: 100, variance: 20 },
      off: { base: 0,   variance: 0  },
    },
    voltage:     { base: 230, vary: 10 },
    powerFactor: { normal: 0.9 },
    activeHours: [8, 22],
  },

  // ── Cleaning (vacuum, 800W) ───────────────────────────────────────────────
  cleaning: {
    initialState: 'off',
    states: ['startup', 'running', 'off'],
    transitions: {
      startup: { next: 'running', minSec: 3,   maxSec: 5    },
      running: { next: 'off',    minSec: 600,  maxSec: 2400 }, // 10-40 min
      off:     { next: 'startup', minSec: 7200, maxSec: 86400 }, // once a day
    },
    power: {
      startup: { base: 1200, variance: 100, inrush: 1.5 },
      running: { base: 800,  variance: 80  },
      off:     { base: 0,    variance: 0   },
    },
    voltage:     { base: 230, vary: 12 },
    powerFactor: { normal: 0.85 },
    activeHours: [9, 20],
  },
};

// ── Singleton state store ─────────────────────────────────────────────────────
// Map<plugId, SimState>
const _plugStates = new Map();

// ── Global simulation controls ──────────────────────────────────────────────
let _scenario     = SCENARIOS.NORMAL;
let _ageFactor    = 1.0;  // 1.0 = new, 1.3 = aged (30% more consumption)
let _loadFactor   = 1.0;  // additional load multiplier for PEAK scenario

// EventEmitter for publishing readings to WebSocket
const simulationEvents = new EventEmitter();

// ── Helpers ───────────────────────────────────────────────────────────────────
function _rand(min, max) {
  return Math.random() * (max - min) + min;
}
function _round(n, dp) {
  return Math.round(n * Math.pow(10, dp)) / Math.pow(10, dp);
}
function _randInt(min, max) {
  return Math.floor(_rand(min, max + 1));
}

/** IST hour (0-23) */
function _istHour() {
  const d = new Date();
  // UTC + 5:30
  return ((d.getUTCHours() * 60 + d.getUTCMinutes() + 330) % 1440) / 60 | 0;
}

/** Check if appliance is within active hours */
function _isActiveHour(model) {
  // Always return true to allow appliances to simulate wattage regardless of the time.
  return true;
}

/** Retrieve model for a given appliance category */
function _getModel(category) {
  return APPLIANCE_MODELS[category] ||
    APPLIANCE_MODELS.other;
}

// ── State machine ─────────────────────────────────────────────────────────────

function _initState(plug, appliance) {
  const category = appliance?.category || 'other';
  const model    = _getModel(category);
  const now      = Date.now();

  return {
    plugId:        plug.plugId,
    category,
    state:         model.initialState,
    stateStartMs:  now,
    stateEndMs:    now + _stateDuration(model, model.initialState),
    lastDefrostMs: now,  // refrigerator defrost tracking
    cycleCount:    0,    // for washing machine runOnce
    thermalOffset: 0,    // heat buildup over time
    ageOffset:     (Math.random() * 0.15) + 0.95, // 0.95-1.10x age variance per device
    scenario:      _scenario,
  };
}

/** Compute duration (ms) for a state from the model */
function _stateDuration(model, state) {
  const t = model.transitions[state];
  if (!t) return 30_000;
  const sec = _randInt(t.minSec, t.maxSec);
  return sec * 1000;
}

/** Advance state machine if current state has expired */
function _advanceState(s, model, now) {
  if (now < s.stateEndMs) return; // still in current state

  const t = model.transitions[s.state];
  if (!t) return;

  // runOnce machines (washing machine): after 'done' → 'off' and stay there a long time
  if (model.runOnce && s.state === 'off') {
    s.stateEndMs = now + _randInt(14400, 86400) * 1000; // 4-24h until next wash
    return;
  }

  s.state        = t.next;
  s.stateStartMs = now;
  s.stateEndMs   = now + _stateDistance(model, t.next, now);
  s.cycleCount++;

  // Thermal buildup: +1-3% after every 3 cooling cycles
  if (s.cycleCount % 3 === 0) {
    s.thermalOffset = Math.min(s.thermalOffset + _rand(0.01, 0.03), 0.12);
  }
}

function _stateDistance(model, state, now) {
  // Check defrost for refrigerator
  if (state === 'compressor_on' &&
      model.defrostIntervalMs &&
      (now - (arguments[3] || 0)) > model.defrostIntervalMs) {
    return 0; // immediately trigger defrost
  }
  return _stateDistance(model, state);
}

// Simpler version without overload confusion
function _stateDistance2(model, state) {
  const t = model.transitions[state];
  if (!t) return 30_000;
  return _randInt(t.minSec, t.maxSec) * 1000;
}

/** Compute wattage for current state */
function _computeWattage(s, model, scenario, options = {}) {
  const pw = model.power[s.state];
  if (!pw) return 0;
  if (pw.base === 0) return 0;

  let w = pw.base;

  // Variance
  if (pw.variance) {
    w += _rand(-pw.variance, pw.variance);
  }

  // Inrush surge at start of state
  const timeInState = Date.now() - s.stateStartMs;
  if (pw.inrush && timeInState < 3000) {
    const surgeFade = 1 - (timeInState / 3000);
    w += pw.base * (pw.inrush - 1) * surgeFade;
  }

  // Thermal drift
  w *= (1 + s.thermalOffset);

  // Device age
  w *= s.ageOffset * _ageFactor;

  // Time-of-day load factor
  const h = _istHour();
  if (h >= 18 && h < 22) w *= _loadFactor; // peak evening hours

  // Hot wash mode for washing machine
  if (s.category === 'laundry' && s.state === 'wash' && pw.hasHeater) {
    if (Math.random() < 0.3) w += 1500; // 30% chance user selected hot wash
  }

  // Scenario overrides
  if (scenario === SCENARIOS.FAULT) {
    // Force abnormal: 2-4× random spike every ~5 readings
    if (Math.random() < 0.2) w *= _rand(2, 4);
  } else if (scenario === SCENARIOS.VACATION) {
    if (!['kitchen_fridge', 'lighting'].includes(s.category)) w = 0;
  } else if (scenario === SCENARIOS.PEAK_HOUR) {
    w *= 1.2;
  } else if (scenario === SCENARIOS.NIGHT) {
    if (['cooling', 'kitchen', 'laundry'].includes(s.category)) w = 0;
  }

  // wattageOverride (from manual trigger)
  if (options.wattageOverride != null) {
    w = options.wattageOverride;
  }

  return Math.max(0, _round(w, 1));
}

/** Compute voltage with grid fluctuation */
function _computeVoltage(model, scenario) {
  const base = model.voltage?.base || VOLTAGE_BASE;
  const vary = model.voltage?.vary || VOLTAGE_VARY;
  let v = base + _rand(-vary, vary);

  if (scenario === SCENARIOS.PEAK_HOUR) {
    v -= _rand(0, VOLTAGE_SAG); // voltage sag during peak
  }
  return _round(v, 1);
}

/** Compute power factor */
function _computePowerFactor(model, state) {
  const pf = model.powerFactor;
  if (!pf) return 0.92;
  if (state === 'startup' && pf.startup) return pf.startup;
  return pf[state] || pf.normal || 0.92;
}

// ── Public API ────────────────────────────────────────────────────────────────

/**
 * Get or create simulation state for a plug.
 * Called before each reading generation.
 */
function getOrInitState(plug, appliance) {
  if (!_plugStates.has(plug.plugId)) {
    _plugStates.set(plug.plugId, _initState(plug, appliance));
  }
  return _plugStates.get(plug.plugId);
}

/**
 * Generate one realistic telemetry reading for a plug.
 * Replaces SmartPlugSimulatorService.readPlug() completely.
 *
 * @param {object} plug       - SmartPlug document
 * @param {object|null} appliance - Linked Appliance (may be null)
 * @param {object} opts       - { wattageOverride?, forceSpike? }
 * @returns {{ wattage, voltage, current, powerFactor, state, isSpike, metadata }}
 */
function readPlug(plug, appliance = null, opts = {}) {
  const category = appliance?.category || 'other';
  const model    = _getModel(category);
  const now      = Date.now();

  // Get or create state
  const s = getOrInitState(plug, appliance);
  s.category = category; // update in case appliance was linked post-init

  // Check active hours — if outside, force to off state
  const isActive = _isActiveHour(model);
  if (!isActive && model.power[s.state]?.base > 0 && s.state !== 'off' && s.state !== 'standby') {
    const offStates = ['off', 'standby', 'sleep'];
    const quietState = model.states.find(st => offStates.includes(st)) || s.state;
    if (quietState !== s.state) {
      s.state        = quietState;
      s.stateStartMs = now;
      s.stateEndMs   = now + _stateDistance2(model, quietState);
    }
  }

  // Advance state machine
  _advanceState(s, model, now);

  // Check refrigerator defrost trigger
  if (category === 'kitchen_fridge' &&
      model.defrostIntervalMs &&
      now - s.lastDefrostMs > model.defrostIntervalMs) {
    s.state        = 'defrost';
    s.stateStartMs = now;
    s.stateEndMs   = now + _stateDistance2(model, 'defrost');
    s.lastDefrostMs = now;
  }

  // Force spike
  if (opts.forceSpike && s.state !== 'off') {
    opts.wattageOverride = (_computeWattage(s, model, _scenario, {}) * _rand(2.5, 4.0));
  }

  // Compute values
  const wattage     = _computeWattage(s, model, _scenario, opts);
  const voltage     = _computeVoltage(model, _scenario);
  const powerFactor = _computePowerFactor(model, s.state);
  const current     = voltage > 0 ? _round(wattage / voltage, 3) : 0;
  const isSpike     = opts.wattageOverride != null && opts.forceSpike;

  return {
    wattage,
    voltage,
    current,
    powerFactor,
    state:      s.state,   // e.g. "cooling", "compressor_on"
    isSpike,
    metadata: {
      category,
      state:         s.state,
      stateAgeMs:    now - s.stateStartMs,
      cycleCount:    s.cycleCount,
      thermalDrift:  _round(s.thermalOffset * 100, 1),
      ageFactor:     _round(s.ageOffset * _ageFactor, 3),
      scenario:      _scenario,
      istHour:       _istHour(),
    },
  };
}

/**
 * Set global simulation scenario.
 * @param {string} scenario - one of SCENARIOS values
 */
function setScenario(scenario) {
  if (!Object.values(SCENARIOS).includes(scenario)) {
    throw new Error(`Unknown scenario: ${scenario}`);
  }
  _scenario  = scenario;
  _loadFactor = scenario === SCENARIOS.PEAK_HOUR ? 1.25 : 1.0;
  _ageFactor  = scenario === SCENARIOS.FAULT     ? 1.5  : 1.0;
  console.log(`[SimulationEngine] Scenario set to: ${scenario}`);
}

/**
 * Force a specific state transition for a plug (manual control).
 * @param {string} plugId
 * @param {string} targetState
 */
function forceState(plugId, targetState) {
  const s = _plugStates.get(plugId);
  if (!s) return false;
  const model = _getModel(s.category);
  if (!model.states.includes(targetState)) return false;
  s.state        = targetState;
  s.stateStartMs = Date.now();
  s.stateEndMs   = Date.now() + _stateDistance2(model, targetState);
  return true;
}

/**
 * Reset a plug's simulation state (soft-restart).
 */
function resetState(plugId) {
  _plugStates.delete(plugId);
}

/**
 * Get current simulation state for all plugs.
 */
function getAllStates() {
  const result = {};
  for (const [plugId, s] of _plugStates.entries()) {
    result[plugId] = {
      state:      s.state,
      category:   s.category,
      scenario:   _scenario,
      cycleCount: s.cycleCount,
    };
  }
  return result;
}

/** Get current scenario */
function getScenario() { return _scenario; }

module.exports = {
  readPlug,
  setScenario,
  forceState,
  resetState,
  getAllStates,
  getScenario,
  getOrInitState,
  simulationEvents,
  SCENARIOS,
};
