// config/firebase.js
// Initialises the Firebase Admin SDK (server-side only).
// The Admin SDK is used solely to VERIFY Firebase ID Tokens issued to the
// Flutter client — we never create or manage users here; Firebase handles that.

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

let initialized = false;
let firebaseAvailable = false;

/**
 * Initialises Firebase Admin SDK.
 * In development, missing credentials produce a warning instead of crashing —
 * the server starts normally and auth-protected routes return 503.
 */
const initFirebase = () => {
    if (initialized) return;
    initialized = true;

    try {
        // Option 1: Service account JSON file (recommended for local dev)
        if (process.env.FIREBASE_SERVICE_ACCOUNT_PATH) {
            const resolvedPath = path.resolve(__dirname, '..', process.env.FIREBASE_SERVICE_ACCOUNT_PATH);

            if (!fs.existsSync(resolvedPath)) {
                throw new Error(`Service account file not found at: ${resolvedPath}`);
            }

            const serviceAccount = JSON.parse(fs.readFileSync(resolvedPath, 'utf8'));
            admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

            // Option 2: Individual env vars (recommended for CI / production)
        } else if (process.env.FIREBASE_PROJECT_ID) {
            admin.initializeApp({
                credential: admin.credential.cert({
                    projectId: process.env.FIREBASE_PROJECT_ID,
                    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
                    privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
                }),
            });

        } else {
            throw new Error(
                'No Firebase credentials found. ' +
                'Set FIREBASE_SERVICE_ACCOUNT_PATH or FIREBASE_PROJECT_ID + FIREBASE_CLIENT_EMAIL + FIREBASE_PRIVATE_KEY.'
            );
        }

        firebaseAvailable = true;
        console.log('🔥  Firebase Admin SDK initialised');

    } catch (err) {
        if (process.env.NODE_ENV === 'production') {
            // Hard crash in production — never run without auth
            throw err;
        }
        // Soft warning in development — server starts, auth routes return 503
        console.warn('⚠️   Firebase Admin SDK NOT initialised (development mode).');
        console.warn(`    Reason: ${err.message}`);
        console.warn('    ➜  Auth-protected routes will return 503 until credentials are added.');
        console.warn('    ➜  GET /health and other public routes work normally.\n');
    }
};

const isFirebaseAvailable = () => firebaseAvailable;

module.exports = { initFirebase, isFirebaseAvailable, admin };
