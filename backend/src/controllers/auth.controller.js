// src/controllers/auth.controller.js
// Auth endpoints for the WattWise backend.
//
// ⚠️  Firebase handles ALL authentication on the Flutter client.
//     The backend does NOT issue tokens, handle passwords, or manage
//     sign-up / sign-in flows. Those are 100% Firebase's job.
//
// This controller exposes one endpoint:
//   POST /api/v1/auth/sync
//     - Called once after the user signs in via Firebase on the Flutter side
//     - Verifies the Firebase ID Token (via authMiddleware)
//     - Creates or returns the MongoDB user profile
//     - Acts as a "first handshake" between the Firebase user and the backend

const { sendSuccess } = require('../utils/ApiResponse');

// ─── POST /api/v1/auth/sync ───────────────────────────────────────────────────
// The authMiddleware already creates the Mongo user if it doesn't exist,
// and attaches it to req.user. This handler just returns it.
exports.syncUser = async (req, res, next) => {
    try {
        return sendSuccess(res, 200, 'User synced successfully.', req.user);
    } catch (error) {
        next(error);
    }
};
