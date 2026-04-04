// src/middleware/authMiddleware.js
// Verifies the Firebase ID Token sent by the Flutter client.
//
// Flow:
//   Flutter  → Firebase Auth (sign-in) → gets idToken
//   Flutter  → sends  Authorization: Bearer <idToken>  in every API request
//   Backend  → this middleware verifies the token with Firebase Admin SDK
//   Backend  → attaches decoded token as req.firebaseUser and the Mongo
//              user document as req.user

const { admin, isFirebaseAvailable } = require('../../config/firebase');
const User = require('../models/User.model');
const ApiError = require('../utils/ApiError');

const authMiddleware = async (req, res, next) => {
    // Guard: Firebase not yet configured (dev env without credentials)
    if (!isFirebaseAvailable()) {
        return next(new ApiError(503, '⚠️  Firebase Auth is not configured on the server. Add credentials to .env to enable protected routes.'));
    }

    try {
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            throw new ApiError(401, 'No token provided. Please sign in first.');
        }

        const idToken = authHeader.split(' ')[1];

        // ── 1. Verify the Firebase ID Token ───────────────────────────────────────
        // This makes a network call to Google's public keys the first time,
        // then caches the result. Throws if expired, invalid, or revoked.
        const decodedToken = await admin.auth().verifyIdToken(idToken, true);
        // `true` checks for revoked tokens (slightly slower but more secure)

        req.firebaseUser = decodedToken; // { uid, email, name, picture, ... }

        // findOne directly uses Mongoose, bypassing UserRepository exclusions.
        // We MUST exclude the large payload fields (-bills -activePlan)
        // because this runs on EVERY authorized request and will otherwise memory-crash Node.
        let user = await User.findOne({ firebaseUid: decodedToken.uid }).select('-bills -activePlan -deviceTokens');

        if (!user) {
            user = await User.create({
                firebaseUid: decodedToken.uid,
                email: decodedToken.email,
                name: decodedToken.name || decodedToken.email.split('@')[0],
                avatarUrl: decodedToken.picture || null,
            });
            console.log(`👤  New user synced to MongoDB: ${user.email}`);
        }

        req.user = user; // full Mongoose document
        next();
    } catch (error) {
        // Firebase throws typed errors; pass through our ApiErrors
        if (error instanceof ApiError) return next(error);

        // Specific Firebase token errors
        const firebaseErrors = ['auth/id-token-expired', 'auth/id-token-revoked', 'auth/argument-error'];
        if (firebaseErrors.some((e) => error.code?.includes(e) || error.message?.includes(e))) {
            return next(new ApiError(401, 'Token expired or revoked. Please sign in again.'));
        }

        console.error("Firebase Auth Error:", error);
        return next(new ApiError(401, 'Authentication failed. Invalid token.'));
    }
};

module.exports = authMiddleware;
