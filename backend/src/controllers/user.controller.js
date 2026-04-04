// src/controllers/user.controller.js
// Updated user controller using service layer

const { sendSuccess } = require("../utils/ApiResponse");
const ApiError = require("../utils/ApiError");
const { asyncHandler } = require("../middleware/errorHandler");
const UserService = require("../services/UserService");
const cacheService = require("../services/CacheService");

const userService = new UserService();

// ─── GET /api/v1/users/me ─────────────────────────────────────────────────────
exports.getMe = asyncHandler(async (req, res, _next) => {
  const cacheKey = cacheService.generateUserKey(req.user._id, "profile");

  // Try to get from cache first
  let userProfile = await cacheService.get(cacheKey);

  if (!userProfile) {
    userProfile = await userService.getUserProfile(req.user._id);

    // Cache for 15 minutes
    await cacheService.set(cacheKey, userProfile, 900);
  }

  sendSuccess(res, 200, "User profile fetched.", userProfile);
});

// ─── PUT /api/v1/users/me ─────────────────────────────────────────────────────
exports.updateMe = asyncHandler(async (req, res, _next) => {
  const { name, avatarUrl } = req.body;

  // Update profile fields
  if (name !== undefined || avatarUrl !== undefined) {
    await userService.updateProfile(req.user._id, { name, avatarUrl });
    await cacheService.del(
      cacheService.generateUserKey(req.user._id, "profile"),
    );
  }

  const userProfile = await userService.getUserProfile(req.user._id);
  sendSuccess(res, 200, "Profile updated.", userProfile);
});

// ─── GET /api/v1/users/me/active-plan ──────────────────────────────────────────
// Returns only activePlan — large payload served on-demand, not on every auth refresh.
exports.getActivePlan = asyncHandler(async (req, res, _next) => {
  const cacheKey = cacheService.generateUserKey(req.user._id, "active-plan");
  let activePlan = await cacheService.get(cacheKey);

  if (!activePlan) {
    activePlan = await userService.getActivePlan(req.user._id);
    if (activePlan) await cacheService.set(cacheKey, activePlan, 1800); // 30-min cache
  }

  sendSuccess(
    res,
    200,
    activePlan ? "Active plan fetched." : "No active plan.",
    activePlan,
  );
});

// ─── POST /api/v1/users/me/streak ────────────────────────────────────────────
// Records a daily check-in, increments streak, and returns the fresh state.
exports.checkIn = asyncHandler(async (req, res, _next) => {
  const result = await userService.recordCheckIn(req.user._id);

  // Invalidate profile cache so next GET /me returns fresh data
  await cacheService.del(cacheService.generateUserKey(req.user._id, "profile"));

  sendSuccess(res, 200, result.message, {
    streak: result.streak,
    lastCheckIn: result.lastCheckIn,
    longestStreak: result.longestStreak,
    alreadyCheckedIn: result.alreadyCheckedIn,
  });
});

// ─── GET /api/v1/users/me/streak ─────────────────────────────────────────────
// Returns the current streak state without modifying it.
exports.getStreak = asyncHandler(async (req, res, _next) => {
  const cacheKey = cacheService.generateUserKey(req.user._id, "streak");
  let streakData = await cacheService.get(cacheKey);

  if (!streakData) {
    streakData = await userService.getStreakData(req.user._id);
    await cacheService.set(cacheKey, streakData, 300); // 5-min cache
  }

  sendSuccess(res, 200, "Streak data fetched.", streakData);
});

// ─── POST /api/v1/users/me/heatmap ───────────────────────────────────────────
// Records today's daily action completion intensity and saves to MongoDB.
// Body: { completedCount: number, totalCount: number }
exports.updateHeatmap = asyncHandler(async (req, res, _next) => {
  const { completedCount, totalCount } = req.body;

  if (typeof completedCount !== "number" || typeof totalCount !== "number") {
    throw new ApiError(400, "completedCount and totalCount must be numbers.");
  }
  if (totalCount < 0 || completedCount < 0 || completedCount > totalCount) {
    throw new ApiError(400, "Invalid completedCount / totalCount values.");
  }

  const result = await userService.recordHeatmapEntry(
    req.user._id,
    completedCount,
    totalCount,
  );

  // Bust the per-month heatmap cache
  const now = new Date();
  const monthKey = `${now.getUTCFullYear()}-${String(now.getUTCMonth() + 1).padStart(2, "0")}`;
  await cacheService.del(
    cacheService.generateUserKey(req.user._id, `heatmap:${monthKey}`),
  );

  sendSuccess(res, 200, "Heatmap updated.", result);
});

// ─── GET /api/v1/users/me/heatmap ────────────────────────────────────────────
// Returns the heatmap for the requested year-month (default: current month).
// Query params: year (number), month (1-12 number)
exports.getHeatmap = asyncHandler(async (req, res, _next) => {
  const now = new Date();
  const year = parseInt(req.query.year) || now.getUTCFullYear();
  const month = parseInt(req.query.month) || now.getUTCMonth() + 1;

  if (month < 1 || month > 12) throw new ApiError(400, "month must be 1–12.");

  const monthKey = `${year}-${String(month).padStart(2, "0")}`;
  const cacheKey = cacheService.generateUserKey(
    req.user._id,
    `heatmap:${monthKey}`,
  );

  let heatmapData = await cacheService.get(cacheKey);

  if (!heatmapData) {
    heatmapData = await userService.getMonthlyHeatmap(
      req.user._id,
      year,
      month,
    );
    // Cache for 10 minutes (data updates on each daily action toggle)
    await cacheService.set(cacheKey, heatmapData, 600);
  }

  sendSuccess(res, 200, "Heatmap fetched.", heatmapData);
});

// ─── PUT /api/v1/users/me/appliances ──────────────────────────────────────────
exports.updateAppliances = asyncHandler(async (_req, _res, _next) => {
  // This endpoint is now deprecated - use appliance controller instead
  throw new ApiError(
    301,
    "This endpoint is deprecated. Use /api/v1/appliances/bulk instead.",
  );
});

// ─── POST /api/v1/users/me/bills ──────────────────────────────────────────
exports.addBill = asyncHandler(async (_req, _res, _next) => {
  // This endpoint is now deprecated - use bill controller instead
  throw new ApiError(
    301,
    "This endpoint is deprecated. Use /api/v1/bills instead.",
  );
});

// ─── PATCH /api/v1/users/me/household ─────────────────────────────────────────────
exports.updateHousehold = asyncHandler(async (req, res, _next) => {
  const updatedUser = await userService.updateHousehold(req.user._id, req.body);

  // Invalidate cache
  await cacheService.del(cacheService.generateUserKey(req.user._id, "profile"));

  sendSuccess(res, 200, "Household updated.", updatedUser);
});

// ─── PATCH /api/v1/users/me/preferences ─────────────────────────────────────────────
exports.updatePreferences = asyncHandler(async (req, res, _next) => {
  const updatedUser = await userService.updatePreferences(
    req.user._id,
    req.body,
  );

  // Invalidate cache
  await cacheService.del(cacheService.generateUserKey(req.user._id, "profile"));

  sendSuccess(res, 200, "Preferences updated.", updatedUser);
});

// ─── POST /api/v1/users/me/device-token ─────────────────────────────────────────────
exports.addDeviceToken = asyncHandler(async (req, res, _next) => {
  const { token, platform } = req.body;

  await userService.addDeviceToken(req.user._id, token, platform);

  sendSuccess(res, 200, "Device token added.");
});

// ─── DELETE /api/v1/users/me/device-token ─────────────────────────────────────────────
exports.removeDeviceToken = asyncHandler(async (req, res, _next) => {
  const { token } = req.body;

  await userService.removeDeviceToken(req.user._id, token);

  sendSuccess(res, 200, "Device token removed.");
});

// ─── POST /api/v1/users/me/complete-onboarding ─────────────────────────────────────────────
exports.completeOnboarding = asyncHandler(async (req, res, _next) => {
  const updatedUser = await userService.completeOnboarding(req.user._id);

  // Invalidate cache
  await cacheService.del(cacheService.generateUserKey(req.user._id, "profile"));

  sendSuccess(res, 200, "Onboarding completed.", updatedUser);
});

// ─── GET /api/v1/users/me/stats ─────────────────────────────────────────────────────
exports.getUserStats = asyncHandler(async (req, res, _next) => {
  const cacheKey = cacheService.generateUserKey(req.user._id, "stats");

  // Try to get from cache first
  let stats = await cacheService.get(cacheKey);

  if (!stats) {
    stats = await userService.getUserStats(req.user._id);

    // Cache for 1 hour
    await cacheService.set(cacheKey, stats, 3600);
  }

  sendSuccess(res, 200, "User stats fetched.", stats);
});

// ─── PATCH /api/v1/users/me/subscription ─────────────────────────────────────────────
exports.updateSubscription = asyncHandler(async (req, res, _next) => {
  const { tier, expiresAt } = req.body;

  const updatedUser = await userService.updateSubscription(
    req.user._id,
    tier,
    expiresAt,
  );

  // Invalidate cache
  await cacheService.del(cacheService.generateUserKey(req.user._id, "profile"));

  sendSuccess(res, 200, "Subscription updated.", updatedUser);
});

// ─── DELETE /api/v1/users/me ─────────────────────────────────────────────────────
exports.deleteAccount = asyncHandler(async (req, res, _next) => {
  await userService.deleteAccount(req.user._id);

  // Clear all user-related cache
  await cacheService.delPattern(
    cacheService.generateUserKey(req.user._id, "*"),
  );

  sendSuccess(res, 200, "Account deleted.");
});

// ─── GET /api/v1/users/search ─────────────────────────────────────────────────────
exports.searchUsers = asyncHandler(async (req, res, _next) => {
  const { q, page = 1, limit = 10 } = req.query;

  if (!q) {
    throw new ApiError(400, "Search query is required");
  }

  const results = await userService.searchUsers(q, {
    pagination: { page, limit },
  });

  sendSuccess(res, 200, "Users found.", results);
});

// ─── GET /api/v1/users/:id ─────────────────────────────────────────────────────
exports.getUserById = asyncHandler(async (req, res, _next) => {
  const user = await userService.getUserById(req.params.id, {
    select: "name email subscriptionTier createdAt",
  });

  if (!user) {
    throw new ApiError(404, "User not found");
  }

  sendSuccess(res, 200, "User fetched.", user);
});

// ─── POST /api/v1/users/export ─────────────────────────────────────────────────────
exports.exportUserData = asyncHandler(async (req, res, _next) => {
  const exportData = await userService.exportUserData(req.user._id);

  sendSuccess(res, 200, "User data exported.", exportData);
});

// ─── GET /api/v1/users/activity ─────────────────────────────────────────────────────
exports.getUserActivity = asyncHandler(async (req, res, _next) => {
  const { page = 1, limit = 20 } = req.query;

  const activities = await userService.getUserActivity(req.user._id, {
    pagination: { page, limit },
  });

  sendSuccess(res, 200, "User activity fetched.", activities);
});

// ─── POST /api/v1/users/verify-email ─────────────────────────────────────────────────────
exports.verifyEmail = asyncHandler(async (req, res, _next) => {
  const { token } = req.body;

  const result = await userService.verifyEmail(token);

  sendSuccess(res, 200, "Email verified.", result);
});

// ─── POST /api/v1/users/forgot-password ─────────────────────────────────────────────────────
exports.forgotPassword = asyncHandler(async (req, res, _next) => {
  const { email } = req.body;

  await userService.forgotPassword(email);

  sendSuccess(res, 200, "Password reset email sent.");
});

// ─── POST /api/v1/users/reset-password ─────────────────────────────────────────────────────
exports.resetPassword = asyncHandler(async (req, res, _next) => {
  const { token, newPassword } = req.body;

  const result = await userService.resetPassword(token, newPassword);

  sendSuccess(res, 200, "Password reset.", result);
});

// ─── Admin endpoints ─────────────────────────────────────────────────────

// ─── GET /api/v1/users/admin/stats ─────────────────────────────────────────────────────
exports.getAdminStats = asyncHandler(async (req, res, _next) => {
  const stats = await userService.getAdminStats();

  sendSuccess(res, 200, "Admin stats fetched.", stats);
});

// ─── GET /api/v1/users/admin/users ─────────────────────────────────────────────────────
exports.getAllUsers = asyncHandler(async (req, res, _next) => {
  const { page = 1, limit = 20, tier, status, search } = req.query;

  const filters = {};
  if (tier) filters.tier = tier;
  if (status) filters.status = status;
  if (search) filters.search = search;

  const results = await userService.getAllUsers({
    pagination: { page, limit },
    filters,
  });

  sendSuccess(res, 200, "Users fetched.", results);
});

// ─── PATCH /api/v1/users/admin/users/:id/status ─────────────────────────────────────────────
exports.updateUserStatus = asyncHandler(async (req, res, _next) => {
  const { status } = req.body;

  const updatedUser = await userService.updateUserStatus(req.params.id, status);

  // Invalidate user cache
  await cacheService.delPattern(
    cacheService.generateUserKey(req.params.id, "*"),
  );

  sendSuccess(res, 200, "User status updated.", updatedUser);
});

// ─── POST /api/v1/users/admin/users/:id/impersonate ─────────────────────────────────────────────
exports.impersonateUser = asyncHandler(async (req, res, _next) => {
  const user = await userService.impersonateUser(req.params.id);

  sendSuccess(res, 200, "User impersonation started.", user);
});
