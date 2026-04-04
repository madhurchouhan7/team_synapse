const express = require('express');
const router = express.Router();

const authMiddleware = require('../middleware/authMiddleware');
const notificationController = require('../controllers/notification.controller');

// All routes require authenticated user
router.use(authMiddleware);

// Device token registration
router.post('/device-token', notificationController.registerDeviceToken);

// List notifications for current user
router.get('/', notificationController.listMyNotifications);

// Mark a single notification as read
router.patch('/:id/read', notificationController.markAsRead);

// Manual/debug send to self
router.post('/send-to-me', notificationController.sendToMe);

module.exports = router;

