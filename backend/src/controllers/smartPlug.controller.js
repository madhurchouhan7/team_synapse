// src/controllers/smartPlug.controller.js
// REST controller for Smart Plug management and telemetry

const SmartPlug          = require('../models/SmartPlug.model');
const TelemetryReading   = require('../models/TelemetryReading.model');
const Appliance          = require('../models/Appliance.model');
const { sendSuccess }    = require('../utils/ApiResponse');
const ApiError           = require('../utils/ApiError');
const { asyncHandler }   = require('../middleware/errorHandler');
const { readPlug }       = require('../services/SmartPlugSimulatorService');
const { analyseReading } = require('../services/AnomalyDetectionService');
const { v4: uuidv4 }     = require('uuid');

// ─── POST /api/v1/smart-plugs ────────────────────────────────────────────────
exports.registerPlug = asyncHandler(async (req, res) => {
  const {
    name,
    applianceId,
    vendor = 'simulator',
    isSimulated = true,
    location,
    baselineWattage,
    connectionConfig,
  } = req.body;

  // Validate linked appliance belongs to user
  if (applianceId) {
    const appliance = await Appliance.findOne({
      _id: applianceId,
      userId: req.user._id,
      isActive: true,
    });
    if (!appliance) {
      throw new ApiError(404, 'Appliance not found or does not belong to you.');
    }
  }

  // Generate a unique plugId for simulated plugs
  const plugId = `${vendor}-${uuidv4().slice(0, 8)}`;

  const plug = await SmartPlug.create({
    userId:         req.user._id,
    applianceId:    applianceId || null,
    plugId,
    name,
    vendor,
    isSimulated,
    location:       location || null,
    baselineWattage: baselineWattage || 0,
    connectionConfig: connectionConfig || {},
    isOnline:       isSimulated, // simulators are always "online"
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
// Manually trigger one telemetry reading (useful for demo / testing anomaly alerts)
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

  const measurement = readPlug(plug, appliance, {
    wattageOverride: wattageOverride != null ? Number(wattageOverride) : undefined,
    forceSpike:      !!forceSpike,
  });

  const result = await analyseReading({
    plug,
    appliance,
    ...measurement,
  });

  sendSuccess(res, 200, 'Telemetry reading recorded.', {
    reading:      result.reading,
    isAnomaly:    result.isAnomaly,
    anomalyScore: result.anomalyScore,
    measurement,
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
