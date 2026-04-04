const Notification = require('../models/Notification.model');
const User = require('../models/User.model');
const { sendSuccess } = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');
const { createAndSendNotification } = require('../services/notification.service');
const { z } = require('zod');

// ─── Device Token Management ───────────────────────────────────────────────────

exports.registerDeviceToken = async (req, res, next) => {
  try {
    const schema = z.object({
      token: z.string().min(10, 'Invalid device token'),
      platform: z.enum(['android', 'ios', 'web', 'unknown']).optional(),
    });

    const parsed = schema.safeParse(req.body);
    if (!parsed.success) {
      throw new ApiError(400, parsed.error.issues.map((i) => i.message).join(', '));
    }

    const { token, platform = 'unknown' } = parsed.data;

    const user = await User.findByIdAndUpdate(
      req.user.id,
      {
        $pull: { deviceTokens: { token } },
      },
      { new: true }
    );

    await User.updateOne(
      { _id: user.id },
      {
        $push: {
          deviceTokens: {
            token,
            platform,
            lastSeenAt: new Date(),
          },
        },
      }
    );

    return sendSuccess(res, 200, 'Device token registered.');
  } catch (err) {
    next(err);
  }
};

// ─── Notification CRUD for current user ───────────────────────────────────────

exports.listMyNotifications = async (req, res, next) => {
  try {
    const notifications = await Notification.find({ user: req.user.id })
      .sort({ sentAt: -1 })
      .limit(100);

    return sendSuccess(res, 200, 'Notifications fetched.', notifications);
  } catch (err) {
    next(err);
  }
};

exports.markAsRead = async (req, res, next) => {
  try {
    const { id } = req.params;
    const notif = await Notification.findOneAndUpdate(
      { _id: id, user: req.user.id },
      { $set: { read: true } },
      { new: true }
    );

    if (!notif) throw new ApiError(404, 'Notification not found.');

    return sendSuccess(res, 200, 'Notification marked as read.', notif);
  } catch (err) {
    next(err);
  }
};

// ─── Manual send (admin / debug) ─────────────────────────────────────────────

exports.sendToMe = async (req, res, next) => {
  try {
    const schema = z.object({
      title: z.string().min(1),
      body: z.string().min(1),
      type: z
        .enum([
          'bill_uploaded',
          'bill_due_soon',
          'high_usage_alert',
          'insight_ready',
          'generic',
        ])
        .optional(),
      data: z.record(z.string(), z.any()).optional(),
    });

    const parsed = schema.safeParse(req.body);
    if (!parsed.success) {
      throw new ApiError(400, parsed.error.issues.map((i) => i.message).join(', '));
    }

    const notification = await createAndSendNotification(req.user._id, parsed.data);

    return sendSuccess(res, 201, 'Notification queued.', notification);
  } catch (err) {
    next(err);
  }
};

