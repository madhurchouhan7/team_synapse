// src/controllers/appliance.controller.js
// Controller for managing user appliances

const Appliance = require("../models/Appliance.model");
const { sendSuccess } = require("../utils/ApiResponse");
const ApiError = require("../utils/ApiError");
const { asyncHandler } = require("../middleware/errorHandler");

const buildConflictEnvelope = (req) => ({
  success: false,
  message: "Precondition failed: appliance was modified. Refresh and retry.",
  errorCode: "PRECONDITION_FAILED",
  requestId: req.id,
  timestamp: new Date().toISOString(),
  details: [{ path: "_expectedVersion", message: "Stale appliance version." }],
});

const conflictOrNotFound = async (req, res) => {
  const latest = await Appliance.findOne({
    _id: req.params.id,
    userId: req.user._id,
    isActive: true,
  });

  if (latest) {
    return res.status(412).json(buildConflictEnvelope(req));
  }

  throw new ApiError(404, "Appliance not found.");
};

// ─── POST /api/v1/appliances ─────────────────────────────────────────────────────
exports.createAppliance = asyncHandler(async (req, res, _next) => {
  const applianceData = {
    ...req.body,
    userId: req.user._id,
  };

  const appliance = await Appliance.create(applianceData);

  sendSuccess(res, 201, "Appliance created successfully.", appliance);
});

// ─── GET /api/v1/appliances ─────────────────────────────────────────────────────
exports.getAppliances = asyncHandler(async (req, res, _next) => {
  const { category, usageLevel } = req.query;

  // Build filter
  const filter = {
    userId: req.user._id,
    isActive: true,
  };

  if (category) filter.category = category;
  if (usageLevel) filter.usageLevel = usageLevel;

  const appliances = await Appliance.find(filter).sort({ createdAt: -1 });

  sendSuccess(res, 200, "Appliances fetched successfully.", appliances);
});

// ─── GET /api/v1/appliances/:id ─────────────────────────────────────────────────────
exports.getAppliance = asyncHandler(async (req, res, _next) => {
  const appliance = await Appliance.findOne({
    _id: req.params.id,
    userId: req.user._id,
    isActive: true,
  });

  if (!appliance) {
    throw new ApiError(404, "Appliance not found.");
  }

  sendSuccess(res, 200, "Appliance fetched successfully.", appliance);
});

// ─── PATCH /api/v1/appliances/:id ─────────────────────────────────────────────────────
exports.updateAppliance = asyncHandler(async (req, res, _next) => {
  const { _expectedVersion, ...patch } = req.body;

  const appliance = await Appliance.findOneAndUpdate(
    {
      _id: req.params.id,
      userId: req.user._id,
      isActive: true,
      __v: _expectedVersion,
    },
    {
      $set: {
        ...patch,
        lastUpdated: new Date(),
      },
      $inc: { __v: 1 },
    },
    { returnDocument: "after", runValidators: true },
  );

  if (!appliance) {
    return conflictOrNotFound(req, res);
  }

  sendSuccess(res, 200, "Appliance updated successfully.", appliance);
});

// ─── DELETE /api/v1/appliances/:id ─────────────────────────────────────────────────────
exports.deleteAppliance = asyncHandler(async (req, res, _next) => {
  const { _expectedVersion } = req.body;

  const appliance = await Appliance.findOneAndUpdate(
    {
      _id: req.params.id,
      userId: req.user._id,
      isActive: true,
      __v: _expectedVersion,
    },
    {
      $set: {
        isActive: false,
        lastUpdated: new Date(),
      },
      $inc: { __v: 1 },
    },
    { returnDocument: "after", runValidators: true },
  );

  if (!appliance) {
    return conflictOrNotFound(req, res);
  }

  sendSuccess(res, 200, "Appliance deleted successfully.");
});

// ─── POST /api/v1/appliances/bulk ─────────────────────────────────────────────────────
exports.updateAppliancesBulk = asyncHandler(async (req, res, _next) => {
  const { appliances } = req.body;

  if (!Array.isArray(appliances)) {
    throw new ApiError(400, "Appliances must be an array.");
  }

  const touchedApplianceIds = appliances
    .map((appliance) => appliance.applianceId)
    .filter(Boolean);

  // Deactivate existing appliances
  await Appliance.updateMany(
    {
      userId: req.user._id,
      isActive: true,
      applianceId: { $in: touchedApplianceIds },
    },
    { isActive: false },
  );

  // Create new appliances
  const appliancesWithUserId = appliances.map((app) => ({
    ...app,
    userId: req.user._id,
  }));

  const newAppliances = await Appliance.insertMany(appliancesWithUserId);

  sendSuccess(res, 200, "Appliances updated successfully.", newAppliances);
});

// ─── GET /api/v1/appliances/summary ─────────────────────────────────────────────────────
exports.getApplianceSummary = asyncHandler(async (req, res, _next) => {
  const summary = await Appliance.aggregate([
    { $match: { userId: req.user._id, isActive: true } },
    {
      $group: {
        _id: null,
        totalAppliances: { $sum: "$count" },
        totalDailyConsumption: {
          $sum: {
            $multiply: ["$wattage", "$usageHoursPerDay", "$count", 0.001],
          },
        },
        totalMonthlyConsumption: {
          $sum: {
            $multiply: ["$wattage", "$usageHoursPerDay", "$count", 30, 0.001],
          },
        },
        byCategory: {
          $push: {
            category: "$category",
            count: "$count",
            dailyConsumption: {
              $multiply: ["$wattage", "$usageHoursPerDay", "$count", 0.001],
            },
          },
        },
        byUsageLevel: {
          $push: {
            usageLevel: "$usageLevel",
            count: "$count",
            dailyConsumption: {
              $multiply: ["$wattage", "$usageHoursPerDay", "$count", 0.001],
            },
          },
        },
      },
    },
  ]);

  const result = summary[0] || {
    totalAppliances: 0,
    totalDailyConsumption: 0,
    totalMonthlyConsumption: 0,
    byCategory: [],
    byUsageLevel: [],
  };

  sendSuccess(res, 200, "Appliance summary fetched successfully.", result);
});

// ─── GET /api/v1/appliances/categories ─────────────────────────────────────────────────────
exports.getApplianceCategories = asyncHandler(async (req, res, _next) => {
  const categories = await Appliance.distinct("category", {
    userId: req.user._id,
    isActive: true,
  });

  sendSuccess(res, 200, "Categories fetched successfully.", categories);
});
