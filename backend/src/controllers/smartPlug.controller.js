// src/controllers/smartPlug.controller.js
// REST controller for Smart Plug management and telemetry

const SmartPlug          = require('../models/SmartPlug.model');
const TelemetryReading   = require('../models/TelemetryReading.model');
const Appliance          = require('../models/Appliance.model');
const { sendSuccess }    = require('../utils/ApiResponse');
const ApiError           = require('../utils/ApiError');
const { asyncHandler }   = require('../middleware/errorHandler');
const SimulationEngine   = require('../services/SimulationEngine');
const TuyaService        = require('../services/TuyaService');
const { analyseReading } = require('../services/AnomalyDetectionService');
const { v4: uuidv4 }     = require('uuid');
const { broadcastReading } = require('../websocket/wsServer');

// ─── POST /api/v1/smart-plugs ────────────────────────────────────────────────
exports.registerPlug = asyncHandler(async (req, res) => {
  const {
    name,
    applianceId,
    vendor = 'simulator',
    isSimulated,
    location,
    baselineWattage,
    connectionConfig,
    tuyaDeviceId,     // Convenience field; also stored in connectionConfig
    // eslint-disable-next-line no-unused-vars
    tuyaRegion,       // Reserved for future multi-region support ('EU'|'US'|'CN'|'IN')
  } = req.body;

  // Validate linked appliance belongs to user
  if (applianceId) {
    const appliance = await Appliance.findOne({
      _id: applianceId,
      userId: req.user._id,
      isActive: true,
    });
    if (!appliance) throw new ApiError(404, 'Appliance not found or does not belong to you.');
  }

  // ── Tuya-specific onboarding ──────────────────────────────────────────────
  const isTuya       = vendor === 'tuya';
  const deviceId     = tuyaDeviceId || connectionConfig?.cloudDeviceId || null;
  const isRealDevice = isTuya && !!deviceId;

  let tuyaDeviceName = name;
  if (isRealDevice) {
    // Validate device exists in Tuya account
    const validation = await TuyaService.validateDevice(deviceId);
    if (!validation.valid) {
      throw new ApiError(
        400,
        `Tuya device not found: ${validation.error || 'Check your Device ID and make sure it is linked to your Tuya IoT project.'}`,
      );
    }
    tuyaDeviceName = name || validation.name;
  }

  // Build plugId
  const plugId = isRealDevice
    ? `tuya-${deviceId.slice(0, 12)}`   // deterministic for real devices
    : `${vendor}-${uuidv4().slice(0, 8)}`;

  // Check for duplicate real Tuya device
  if (isRealDevice) {
    const exists = await SmartPlug.findOne({
      userId:   req.user._id,
      'connectionConfig.cloudDeviceId': deviceId,
      isActive: true,
    });
    if (exists) throw new ApiError(409, 'This Tuya device is already registered.');
  }

  const plug = await SmartPlug.create({
    userId:           req.user._id,
    applianceId:      applianceId || null,
    plugId,
    name:             tuyaDeviceName,
    vendor,
    isSimulated:      isSimulated !== undefined ? isSimulated : !isRealDevice,
    location:         location || null,
    baselineWattage:  baselineWattage || 0,
    connectionConfig: {
      ...(connectionConfig || {}),
      cloudDeviceId: deviceId || connectionConfig?.cloudDeviceId || null,
    },
    isOnline: !isTuya, // simulators are always online; Tuya online status comes from first poll
  });

  sendSuccess(res, 201, 'Smart plug registered successfully.', plug);
});

// ─── GET /api/v1/smart-plugs ─────────────────────────────────────────────────
exports.getPlugs = asyncHandler(async (req, res) => {
  const plugs = await SmartPlug.find({ userId: req.user._id, isActive: true })
    .populate('applianceId', 'title category wattage svgPath')
    .sort({ createdAt: -1 });

  sendSuccess(res, 200, 'Smart plugs fetched successfully.', plugs);
});

// ─── GET /api/v1/smart-plugs/:id ─────────────────────────────────────────────
exports.getPlug = asyncHandler(async (req, res) => {
  const plug = await SmartPlug.findOne({
    _id:    req.params.id,
    userId: req.user._id,
    isActive: true,
  }).populate('applianceId', 'title category wattage svgPath');

  if (!plug) throw new ApiError(404, 'Smart plug not found.');

  sendSuccess(res, 200, 'Smart plug fetched.', plug);
});

// ─── DELETE /api/v1/smart-plugs/:id ──────────────────────────────────────────
exports.deletePlug = asyncHandler(async (req, res) => {
  const plug = await SmartPlug.findOneAndUpdate(
    { _id: req.params.id, userId: req.user._id, isActive: true },
    { $set: { isActive: false, isOnline: false } },
    { new: true },
  );

  if (!plug) throw new ApiError(404, 'Smart plug not found.');

  sendSuccess(res, 200, 'Smart plug unregistered.');
});

// ─── GET /api/v1/smart-plugs/:id/telemetry ───────────────────────────────────
exports.getTelemetry = asyncHandler(async (req, res) => {
  const plug = await SmartPlug.findOne({
    _id:    req.params.id,
    userId: req.user._id,
    isActive: true,
  });
  if (!plug) throw new ApiError(404, 'Smart plug not found.');

  const limit  = Math.min(parseInt(req.query.limit) || 50, 200);
  const onlyAnomalies = req.query.anomalies === 'true';

  const filter = { plugId: plug.plugId };
  if (onlyAnomalies) filter.isAnomaly = true;

  const readings = await TelemetryReading.find(filter)
    .sort({ timestamp: -1 })
    .limit(limit)
    .lean();

  const anomalyCount = await TelemetryReading.countDocuments({
    plugId:    plug.plugId,
    isAnomaly: true,
  });

  sendSuccess(res, 200, 'Telemetry fetched.', {
    plug,
    readings,
    anomalyCount,
    totalFetched: readings.length,
  });
});

// ─── POST /api/v1/smart-plugs/:id/simulate ───────────────────────────────────
exports.triggerReading = asyncHandler(async (req, res) => {
  const plug = await SmartPlug.findOne({
    _id:    req.params.id,
    userId: req.user._id,
    isActive: true,
  });
  if (!plug) throw new ApiError(404, 'Smart plug not found.');

  const appliance = plug.applianceId
    ? await Appliance.findById(plug.applianceId).lean()
    : null;

  const { wattageOverride, forceSpike } = req.body;

  // Use SimulationEngine for manual triggers even for Tuya plugs (demo convenience)
  const measurement = SimulationEngine.readPlug(plug, appliance, {
    wattageOverride: wattageOverride != null ? Number(wattageOverride) : undefined,
    forceSpike:      !!forceSpike,
  });

  const result = await analyseReading({ plug, appliance, ...measurement });
  
  // Real-time broadcast so the dashboard/banner reacts instantly
  broadcastReading(
    result.reading,
    plug.name,
    appliance?.title || plug.name,
    { deviceState: measurement.state, isSpike: measurement.isSpike }
  );

  sendSuccess(res, 200, 'Telemetry reading recorded.', {
    reading:      result.reading,
    isAnomaly:    result.isAnomaly,
    anomalyScore: result.anomalyScore,
    measurement,
  });
});

// ─── GET /api/v1/smart-plugs/tuya-devices ────────────────────────────────────
// List all Tuya devices in the configured account (for onboarding/discovery)
exports.listTuyaDevices = asyncHandler(async (req, res) => {
  const page     = parseInt(req.query.page)     || 1;
  const pageSize = parseInt(req.query.pageSize) || 20;

  const result = await TuyaService.listDevices({ page, pageSize });
  sendSuccess(res, 200, 'Tuya devices fetched.', result);
});

// ─── POST /api/v1/smart-plugs/:id/control ────────────────────────────────────
// Turn a real Tuya plug on or off
exports.controlPlug = asyncHandler(async (req, res) => {
  const plug = await SmartPlug.findOne({
    _id:      req.params.id,
    userId:   req.user._id,
    isActive: true,
  });
  if (!plug) throw new ApiError(404, 'Smart plug not found.');

  if (plug.vendor !== 'tuya' || plug.isSimulated) {
    throw new ApiError(400, 'Control commands are only supported for real Tuya plugs.');
  }

  const deviceId = plug.connectionConfig?.cloudDeviceId;
  if (!deviceId) throw new ApiError(400, 'Plug has no Tuya device ID configured.');

  const { turnOn } = req.body;
  if (turnOn === undefined) throw new ApiError(400, 'turnOn (boolean) is required.');

  await TuyaService.setPlugState(deviceId, !!turnOn);

  // Quick status snapshot after command
  const metrics = await TuyaService.readPlugMetrics(deviceId);

  sendSuccess(res, 200, `Plug turned ${turnOn ? 'on' : 'off'}.`, {
    plugId:  plug.plugId,
    isOn:    metrics.isOn,
    wattage: metrics.wattage,
  });
});

// ─── GET /api/v1/smart-plugs/summary ─────────────────────────────────────────
// Aggregate summary across all user's plugs (for dashboard widget)
exports.getSummary = asyncHandler(async (req, res) => {
  const plugs = await SmartPlug.find({ userId: req.user._id, isActive: true })
    .populate('applianceId', 'title category')
    .lean();

  const totalPlugs   = plugs.length;
  const onlinePlugs  = plugs.filter((p) => p.isOnline).length;
  const anomalyPlugs = plugs.filter((p) => p.lastReading?.isAnomaly).length;

  const liveWattage = plugs.reduce((sum, p) => sum + (p.lastReading?.wattage || 0), 0);

  // Recent unread anomalies (last 24h)
  const since = new Date(Date.now() - 24 * 60 * 60 * 1000);
  const recentAnomalies = await TelemetryReading.find({
    userId:    req.user._id,
    isAnomaly: true,
    timestamp: { $gte: since },
  })
    .sort({ timestamp: -1 })
    .limit(10)
    .lean();

  sendSuccess(res, 200, 'Smart plug summary fetched.', {
    totalPlugs,
    onlinePlugs,
    anomalyPlugs,
    liveWattage: Math.round(liveWattage),
    recentAnomalies,
    plugs: plugs.map((p) => ({
      id:          p._id,
      plugId:      p.plugId,
      name:        p.name,
      location:    p.location,
      isOnline:    p.isOnline,
      isSimulated: p.isSimulated,
      lastReading: p.lastReading,
      appliance:   p.applianceId,
    })),
  });
});
