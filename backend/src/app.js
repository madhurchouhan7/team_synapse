// src/app.js
// Entry point for the WattWise Express API

require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const { v4: uuidv4 } = require('uuid');

const { initFirebase } = require('../config/firebase');
const connectDB = require('../config/db');
const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');
const { sanitizeInput, preventNoSQLInjection, contentSecurityPolicy } = require('./middleware/security.middleware');
const { rateLimiters, rateLimitStatus } = require('./middleware/rateLimit.middleware');
const { versionMiddleware } = require('./middleware/apiVersioning');
const { requestLogger, errorLogger, activityLogger, performanceLogger, securityLogger } = require('./middleware/logging.middleware');
const apiRoutes = require('./routes/index');
const healthRoutes = require('./routes/health.routes');

// ─── Initialise Firebase Admin SDK ────────────────────────────────────────────
initFirebase();

// ─── Connect to Database ───────────────────────────────────────────────────────
connectDB();

const app = express();

// ─── Request ID Middleware ───────────────────────────────────────────────────
app.use((req, res, next) => {
    req.id = uuidv4();
    res.setHeader('X-Request-ID', req.id);
    next();
});

// ─── Logging Middleware ─────────────────────────────────────────────────────
app.use(requestLogger());
app.use(activityLogger());
app.use(performanceLogger());
app.use(securityLogger());
app.use(errorLogger());

// ─── API Versioning ─────────────────────────────────────────────────────
app.use(versionMiddleware());

// ─── Security Middleware ───────────────────────────────────────────────────────
app.use(helmet());
app.use(contentSecurityPolicy);
app.use(sanitizeInput);
app.use(preventNoSQLInjection);

// ─── CORS ─────────────────────────────────────────────────────────────────────
const allowedOrigins = process.env.ALLOWED_ORIGINS
    ? process.env.ALLOWED_ORIGINS.split(',').map((o) => o.trim())
    : [];

app.use(
    cors({
        origin: (origin, callback) => {
            // Allow requests with no origin (mobile apps, curl, Postman)
            if (!origin || allowedOrigins.length === 0 || allowedOrigins.includes(origin)) {
                return callback(null, true);
            }
            callback(new Error(`CORS policy: origin ${origin} not allowed`));
        },
        credentials: true,
    })
);

// ─── Rate Limiting ─────────────────────────────────────────────────────────────
app.use('/api', rateLimiters.general);
app.use(rateLimitStatus);

// Apply stricter rate limiting to sensitive endpoints
app.use('/api/v1/auth', rateLimiters.auth);
app.use('/api/v1/ai', rateLimiters.ai);
app.use('/api/v1/bbps', rateLimiters.billFetch);

// ─── Body Parsing ──────────────────────────────────────────────────────────────
app.use(express.json({ limit: '5mb' }));
app.use(express.urlencoded({ extended: true, limit: '5mb' }));

// ─── Logging ──────────────────────────────────────────────────────────────────
if (process.env.NODE_ENV !== 'test') {
    app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));
}

// ─── Health Check Routes ─────────────────────────────────────────────────────
app.use('/health', healthRoutes);

// ─── Root Endpoint ───────────────────────────────────────────────────────
app.get('/', (req, res) => {
    res.json({
        message: 'WattWise API is running 🚀',
        environment: process.env.NODE_ENV,
        timestamp: new Date().toISOString(),
        version: process.env.npm_package_version || '1.0.0',
        health: '/health',
        api: '/api/v1',
        documentation: 'https://docs.wattwise.com'
    });
});

// ─── API Routes ───────────────────────────────────────────────────────
app.use('/api/v1', apiRoutes);

// ─── 404 Handler ──────────────────────────────────────────────────────
app.use(notFoundHandler);

// ─── Global Error Handler ─────────────────────────────────────────────────────
app.use(errorHandler);

// ─── Graceful Shutdown ─────────────────────────────────────────────────────
process.on('SIGTERM', () => {
    console.log('SIGTERM received, shutting down gracefully');
    // Close database connections, cache, etc.
    process.exit(0);
});

process.on('SIGINT', () => {
    console.log('SIGINT received, shutting down gracefully');
    // Close database connections, cache, etc.
    process.exit(0);
});

// ─── Start Server ─────────────────────────────────────────────────────
const PORT = process.env.PORT || 5000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀  WattWise API running on port ${PORT} [${process.env.NODE_ENV}]`);
    console.log(`📊 Health checks available at http://localhost:${PORT}/health`);
    console.log(`📚 API documentation at http://localhost:${PORT}/api/v1`);
});

module.exports = app; // for testing
