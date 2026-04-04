// src/controllers/simulation.controller.js
// REST endpoints for controlling the simulation engine (demo/prototype use)

const SimulationEngine = require('../services/SimulationEngine');
const SmartPlug        = require('../models/SmartPlug.model');
const Appliance        = require('../models/Appliance.model');
const { sendSuccess }  = require('../utils/ApiResponse');
const ApiError         = require('../utils/ApiError');
const { asyncHandler } = require('../middleware/errorHandler');
const { analyseReading } = require('../services/AnomalyDetectionService');
const {
  broadcastReading,
  broadcastAnomaly,
  connectedCount,
} = require('../websocket/wsServer');

// ── GET /api/v1/simulation/status ────────────────────────────────────────────
exports.getStatus = asyncHandler(async (req, res) => {
  const scenario     = SimulationEngine.getScenario();
  const plugStates   = SimulationEngine.getAllStates();
  const wsClients    = connectedCount();

  const plugCount = await SmartPlug.countDocuments({
    userId:   req.user._id,
    isActive: true,
  });

  sendSuccess(res, 200, 'Simulation status.', {
    scenario,
    plugCount,
    wsConnectedClients: wsClients,
    plugStates,
    scenarios: SimulationEngine.SCENARIOS,
  });
});

// ── POST /api/v1/simulation/scenario ─────────────────────────────────────────
// Body: { scenario: 'normal' | 'peak_hour' | 'night' | 'fault' | 'vacation' }
exports.setScenario = asyncHandler(async (req, res) => {
  const { scenario } = req.body;
  if (!scenario) throw new ApiError(400, 'scenario field is required');

  try {
    SimulationEngine.setScenario(scenario);
  } catch (err) {
    throw new ApiError(400, err.message);
  }

  sendSuccess(res, 200, `Scenario set to "${scenario}".`, { scenario });
});

// ── POST /api/v1/simulation/plug/:id/trigger ─────────────────────────────────
// Manually trigger one reading with optional overrides
exports.triggerPlug = asyncHandler(async (req, res) => {
  const plug = await SmartPlug.findOne({
    _id:      req.params.id,
    userId:   req.user._id,
    isActive: true,
  });
  if (!plug) throw new ApiError(404, 'Smart plug not found.');

  const appliance = plug.applianceId
    ? await Appliance.findById(plug.applianceId).lean()
    : null;

  const { wattageOverride, forceSpike, forceState } = req.body || {};

  // Force state machine to a specific state if requested
  if (forceState) {
    const ok = SimulationEngine.forceState(plug.plugId, forceState);
    if (!ok) throw new ApiError(400, `Invalid state "${forceState}" for this appliance.`);
  }

  const measurement = SimulationEngine.readPlug(plug, appliance, {
    wattageOverride: wattageOverride != null ? Number(wattageOverride) : undefined,
    forceSpike:      !!forceSpike,
  });

  const { reading, isAnomaly, anomalyScore } = await analyseReading({
    plug,
    appliance,
    ...measurement,
  });

  // Broadcast to WebSocket
  broadcastReading(
    reading,
    plug.name,
    appliance?.title || plug.name,
    { deviceState: measurement.state, metadata: measurement.metadata },
  );
  if (isAnomaly) {
    broadcastAnomaly(plug.userId, {
      plugId:        plug.plugId,
      plugName:      plug.name,
      applianceName: appliance?.title || plug.name,
      wattage:       reading.wattage,
      anomalyScore,
      anomalyReason: reading.anomalyReason,
      timestamp:     reading.timestamp,
    });
  }

  sendSuccess(res, 200, 'Reading triggered.', {
    reading,
    isAnomaly,
    anomalyScore,
    deviceState: measurement.state,
    metadata:    measurement.metadata,
  });
});

// ── POST /api/v1/simulation/plug/:id/state ───────────────────────────────────
// Force a specific device state (e.g. force AC into 'startup')
exports.forcePlugState = asyncHandler(async (req, res) => {
  const plug = await SmartPlug.findOne({
    _id:      req.params.id,
    userId:   req.user._id,
    isActive: true,
  });
  if (!plug) throw new ApiError(404, 'Smart plug not found.');

  const { state } = req.body;
  if (!state) throw new ApiError(400, 'state field is required');

  const ok = SimulationEngine.forceState(plug.plugId, state);
  if (!ok) throw new ApiError(400, `Invalid state "${state}" for appliance category.`);

  sendSuccess(res, 200, `Plug state forced to "${state}".`, {
    plugId: plug.plugId,
    state,
  });
});

// ── DELETE /api/v1/simulation/plug/:id/reset ─────────────────────────────────
// Reset a plug's simulation state (re-randomizes everything)
exports.resetPlugState = asyncHandler(async (req, res) => {
  const plug = await SmartPlug.findOne({
    _id:      req.params.id,
    userId:   req.user._id,
    isActive: true,
  });
  if (!plug) throw new ApiError(404, 'Smart plug not found.');

  SimulationEngine.resetState(plug.plugId);
  sendSuccess(res, 200, 'Plug simulation state reset.', { plugId: plug.plugId });
});

// ── GET /api/v1/simulation/scenarios ────────────────────────────────────────
// Returns all known scenarios with descriptions (for Flutter dropdown)
exports.listScenarios = asyncHandler(async (req, res) => {
  sendSuccess(res, 200, 'Available scenarios.', {
    current: SimulationEngine.getScenario(),
    scenarios: [
      {
        id:          'normal',
        label:       'Normal Day',
        description: 'Typical household usage patterns throughout the day.',
        icon:        'home',
      },
      {
        id:          'peak_hour',
        label:       'Peak Hour (6-10 PM)',
        description: 'High simultaneous load — AC, cooking, entertainment. Voltage sag likely.',
        icon:        'flash_on',
      },
      {
        id:          'night',
        label:       'Night Mode',
        description: 'Minimal appliances. Cooling and kitchen loads suspended.',
        icon:        'nights_stay',
      },
      {
        id:          'fault',
        label:       'Device Fault',
        description: 'Simulates faulty appliances with abnormal power spikes. Triggers anomaly alerts.',
        icon:        'warning',
      },
      {
        id:          'vacation',
        label:       'Vacation / Away',
        description: 'Only refrigerator and minimal lighting active.',
        icon:        'flight',
      },
    ],
  });
});
