const { admin, isFirebaseAvailable } = require('../../config/firebase');
const Notification = require('../models/Notification.model');
const User = require('../models/User.model');

/**
 * Core notification service.
 * - Persists notification to Mongo
 * - Attempts to deliver via FCM to all known device tokens
 * - Gracefully degrades if FCM is not configured
 */

/**
 * Create and (optionally) send a notification to a user.
 *
 * @param {string|import('mongoose').Types.ObjectId} userId
 * @param {{ title: string; body: string; type?: string; data?: object }} payload
 * @returns {Promise<import('../models/Notification.model')>}
 */
async function createAndSendNotification(userId, payload) {
  const { title, body, type = 'generic', data = {} } = payload;

  // 1. Persist the notification
  const notification = await Notification.create({
    user: userId,
    title,
    body,
    type,
    data,
  });

  // 2. Try to send via FCM (best-effort)
  if (!isFirebaseAvailable()) {
    // FCM not configured (dev env) — we still keep the notification in DB
    return notification;
  }

  const user = await User.findById(userId).lean();
  if (!user || !Array.isArray(user.deviceTokens) || user.deviceTokens.length === 0) {
    return notification;
  }

  const tokens = user.deviceTokens.map((dt) => dt.token).filter(Boolean);
  if (tokens.length === 0) return notification;

  const message = {
    notification: {
      title,
      body,
    },
    data: {
      type,
      notificationId: notification._id.toString(),
      ...Object.entries(data || {}).reduce((acc, [k, v]) => {
        acc[String(k)] = String(v);
        return acc;
      }, {}),
    },
  };

  try {
    // Use multicast so a single user can have multiple devices
    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      ...message,
    });

    if (response.failureCount > 0) {
      const invalidTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const code = resp.error && resp.error.code;
          if (
            code === 'messaging/registration-token-not-registered' ||
            code === 'messaging/invalid-registration-token'
          ) {
            invalidTokens.push(tokens[idx]);
          }
        }
      });

      if (invalidTokens.length > 0) {
        await User.updateOne(
          { _id: userId },
          { $pull: { deviceTokens: { token: { $in: invalidTokens } } } }
        );
      }

      await Notification.findByIdAndUpdate(notification._id, {
        $set: {
          error: `Partial delivery failures: ${response.failureCount}`,
        },
      });
    }
  } catch (err) {
    await Notification.findByIdAndUpdate(notification._id, {
      $set: { error: err.message || 'FCM send failed' },
    });
  }

  return notification;
}

module.exports = {
  createAndSendNotification,
};

