// src/middleware/logging.middleware.js
// Comprehensive request/response logging middleware

const { v4: uuidv4 } = require('uuid');
const cacheService = require('../services/CacheService');

class LoggingMiddleware {
    constructor() {
        this.logLevels = {
            error: 0,
            warn: 1,
            info: 2,
            debug: 3
        };
        this.currentLogLevel = this.logLevels[process.env.LOG_LEVEL || 'info'] || 2;
    }

    // ─── Request Logging ─────────────────────────────────────────────────────

    requestLogger() {
        return (req, res, next) => {
            const startTime = Date.now();
            const requestId = req.id || uuidv4();

            // Add request ID to request object
            req.id = requestId;
            res.setHeader('X-Request-ID', requestId);

            // Log request details
            loggingMiddleware.logRequest(req, requestId);

            // Override res.end to log response
            const originalEnd = res.end;
            res.end = function (chunk, encoding) {
                const duration = Date.now() - startTime;
                loggingMiddleware.logResponse(req, res, duration, requestId);
                originalEnd.call(this, chunk, encoding);
            };

            next();
        };
    }

    logRequest(req, requestId) {
        const logData = {
            type: 'request',
            requestId,
            timestamp: new Date().toISOString(),
            method: req.method,
            url: req.originalUrl || req.url,
            ip: req.ip || req.connection.remoteAddress,
            userAgent: req.get('User-Agent'),
            contentType: req.get('Content-Type'),
            contentLength: req.get('Content-Length'),
            apiVersion: req.apiVersion,
            userId: req.user?.id || req.user?._id,
            path: req.path,
            query: req.query,
            // Log body only for non-sensitive endpoints
            body: loggingMiddleware.shouldLogBody(req) ? loggingMiddleware.sanitizeBody(req.body) : '[REDACTED]'
        };

        loggingMiddleware.log('info', 'HTTP Request', logData);
    }

    logResponse(req, res, duration, requestId) {
        const logData = {
            type: 'response',
            requestId,
            timestamp: new Date().toISOString(),
            statusCode: res.statusCode,
            statusMessage: res.statusMessage,
            duration: `${duration}ms`,
            contentLength: res.get('Content-Length'),
            contentType: res.get('Content-Type'),
            apiVersion: req.apiVersion,
            userId: req.user?.id || req.user?._id,
            // Rate limit info if available
            rateLimit: {
                limit: res.get('X-RateLimit-Limit'),
                remaining: res.get('X-RateLimit-Remaining'),
                reset: res.get('X-RateLimit-Reset')
            }
        };

        const level = loggingMiddleware.getLogLevel(res.statusCode);
        loggingMiddleware.log(level, 'HTTP Response', logData);
    }

    // ─── Error Logging ─────────────────────────────────────────────────────

    errorLogger() {
        return (err, req, res, next) => {
            const logData = {
                type: 'error',
                requestId: req.id,
                timestamp: new Date().toISOString(),
                error: {
                    name: err.name,
                    message: err.message,
                    stack: err.stack,
                    code: err.code,
                    statusCode: err.statusCode
                },
                request: {
                    method: req.method,
                    url: req.originalUrl || req.url,
                    ip: req.ip,
                    userId: req.user?.id || req.user?._id,
                    apiVersion: req.apiVersion,
                    body: loggingMiddleware.shouldLogBody(req) ? loggingMiddleware.sanitizeBody(req.body) : '[REDACTED]'
                }
            };

            loggingMiddleware.log('error', 'Application Error', logData);
            next(err);
        };
    }

    // ─── Business Activity Logging ─────────────────────────────────────────────

    activityLogger() {
        return (req, res, next) => {
            // Store original methods
            const originalSend = res.send;

            // Override send to capture business activities
            res.send = function (data) {
                // Log successful business operations
                if (res.statusCode >= 200 && res.statusCode < 300 && req.user) {
                    LoggingMiddleware.prototype.logBusinessActivity(req, res, data);
                }

                originalSend.call(this, data);
            };

            next();
        };
    }

    logBusinessActivity(req, res, responseData) {
        const activity = loggingMiddleware.extractActivity(req, res, responseData);

        if (!activity) return;

        const logData = {
            type: 'activity',
            timestamp: new Date().toISOString(),
            requestId: req.id,
            userId: req.user?.id || req.user?._id,
            action: activity.action,
            resource: activity.resource,
            resourceId: activity.resourceId,
            details: activity.details,
            metadata: {
                method: req.method,
                url: req.originalUrl,
                ip: req.ip,
                userAgent: req.get('User-Agent'),
                apiVersion: req.apiVersion
            }
        };

        loggingMiddleware.log('info', 'Business Activity', logData);

        // Store activity in cache for recent activity tracking
        loggingMiddleware.storeActivity(logData);
    }

    extractActivity(req, res, responseData) {
        const path = req.path;
        const method = req.method;

        // Define activity mappings
        const activityMap = {
            'POST:/api/v1/addresses': { action: 'create', resource: 'address' },
            'PATCH:/api/v1/addresses/:id': { action: 'update', resource: 'address' },
            'DELETE:/api/v1/addresses/:id': { action: 'delete', resource: 'address' },
            'POST:/api/v1/appliances': { action: 'create', resource: 'appliance' },
            'PATCH:/api/v1/appliances/:id': { action: 'update', resource: 'appliance' },
            'DELETE:/api/v1/appliances/:id': { action: 'delete', resource: 'appliance' },
            'POST:/api/v1/bills': { action: 'create', resource: 'bill' },
            'PATCH:/api/v1/bills/:id': { action: 'update', resource: 'bill' },
            'DELETE:/api/v1/bills/:id': { action: 'delete', resource: 'bill' },
            'PATCH:/api/v1/users/me': { action: 'update', resource: 'profile' },
            'POST:/api/v1/users/me/device-token': { action: 'add', resource: 'device_token' },
            'DELETE:/api/v1/users/me/device-token': { action: 'remove', resource: 'device_token' }
        };

        // Find matching activity
        const activityKey = `${method}:${path.replace(/\/[^/]+$/, '/:id')}`;
        const activity = activityMap[activityKey];

        if (!activity) return null;

        return {
            ...activity,
            resourceId: req.params.id || loggingMiddleware.extractResourceId(responseData),
            details: loggingMiddleware.extractActivityDetails(req, responseData)
        };
    }

    extractResourceId(responseData) {
        if (responseData && typeof responseData === 'object') {
            return responseData.id || responseData._id || null;
        }
        return null;
    }

    extractActivityDetails(req, responseData) {
        const details = {};

        // Extract relevant details based on the endpoint
        if (req.path.includes('/appliances')) {
            details.applianceCount = Array.isArray(req.body?.appliances) ? req.body.appliances.length : 1;
        }

        if (req.path.includes('/bills')) {
            details.billAmount = req.body?.amount || responseData?.amount;
            details.billUnits = req.body?.units || responseData?.units;
        }

        return details;
    }

    // ─── Performance Logging ─────────────────────────────────────────────────

    performanceLogger() {
        return (req, res, next) => {
            const startTime = process.hrtime.bigint();

            res.on('finish', () => {
                const endTime = process.hrtime.bigint();
                const duration = Number(endTime - startTime) / 1000000; // Convert to milliseconds

                const logData = {
                    type: 'performance',
                    timestamp: new Date().toISOString(),
                    requestId: req.id,
                    method: req.method,
                    url: req.originalUrl,
                    duration: `${duration.toFixed(2)}ms`,
                    statusCode: res.statusCode,
                    userId: req.user?.id || req.user?._id,
                    apiVersion: req.apiVersion,
                    memoryUsage: process.memoryUsage(),
                    cpuUsage: process.cpuUsage()
                };

                // Log slow requests
                if (duration > 1000) {
                    loggingMiddleware.log('warn', 'Slow Request Detected', logData);
                } else {
                    loggingMiddleware.log('debug', 'Request Performance', logData);
                }
            });

            next();
        };
    }

    // ─── Security Logging ─────────────────────────────────────────────────

    securityLogger() {
        return (req, res, next) => {
            // Log security events
            loggingMiddleware.logSecurityEvent(req);

            next();
        };
    }

    logSecurityEvent(req) {
        const securityEvents = [];

        // Check for suspicious patterns
        if (loggingMiddleware.isSuspiciousRequest(req)) {
            securityEvents.push({
                type: 'suspicious_request',
                reason: 'Request contains suspicious patterns',
                details: loggingMiddleware.getSuspiciousDetails(req)
            });
        }

        // Check for rate limit violations
        if (req.rateLimit && req.rateLimit.remaining === 0) {
            securityEvents.push({
                type: 'rate_limit_exceeded',
                reason: 'Rate limit exceeded',
                details: {
                    limit: req.rateLimit.limit,
                    resetTime: req.rateLimit.reset
                }
            });
        }

        // Log security events
        securityEvents.forEach(event => {
            const logData = {
                type: 'security',
                timestamp: new Date().toISOString(),
                requestId: req.id,
                userId: req.user?.id || req.user?._id,
                ip: req.ip,
                userAgent: req.get('User-Agent'),
                ...event
            };

            loggingMiddleware.log('warn', 'Security Event', logData);
        });
    }

    isSuspiciousRequest(req) {
        const suspiciousPatterns = [
            /\.\./,  // Path traversal
            /<script/i,  // XSS attempt
            /union.*select/i,  // SQL injection attempt
            /\$where/i,  // NoSQL injection attempt
            /javascript:/i,  // JavaScript protocol
        ];

        const url = req.originalUrl || req.url;
        const body = JSON.stringify(req.body || {});
        const query = JSON.stringify(req.query || {});

        const combined = `${url} ${body} ${query}`;

        return suspiciousPatterns.some(pattern => pattern.test(combined));
    }

    getSuspiciousDetails(req) {
        return {
            url: req.originalUrl,
            method: req.method,
            query: req.query,
            body: loggingMiddleware.sanitizeBody(req.body),
            headers: loggingMiddleware.sanitizeHeaders(req.headers)
        };
    }

    // ─── Utility Methods ─────────────────────────────────────────────────

    shouldLogBody(req) {
        // Don't log sensitive endpoints
        const sensitiveEndpoints = [
            '/auth/login',
            '/auth/register',
            '/auth/refresh',
            '/users/me/password',
            '/users/forgot-password',
            '/users/reset-password'
        ];

        return !sensitiveEndpoints.some(endpoint => req.path.includes(endpoint));
    }

    sanitizeBody(body) {
        if (!body || typeof body !== 'object') return body;

        const sensitiveFields = [
            'password',
            'token',
            'secret',
            'key',
            'creditCard',
            'ssn',
            'bankAccount'
        ];

        const sanitized = { ...body };

        sensitiveFields.forEach(field => {
            if (sanitized[field]) {
                sanitized[field] = '[REDACTED]';
            }
        });

        return sanitized;
    }

    sanitizeHeaders(headers) {
        const sensitiveHeaders = [
            'authorization',
            'cookie',
            'x-api-key'
        ];

        const sanitized = { ...headers };

        sensitiveHeaders.forEach(header => {
            if (sanitized[header]) {
                sanitized[header] = '[REDACTED]';
            }
        });

        return sanitized;
    }

    getLogLevel(statusCode) {
        if (statusCode >= 500) return 'error';
        if (statusCode >= 400) return 'warn';
        if (statusCode >= 300) return 'info';
        return 'info';
    }

    log(level, message, data) {
        if (loggingMiddleware.logLevels[level] > loggingMiddleware.currentLogLevel) return;

        const logEntry = {
            level,
            message,
            timestamp: new Date().toISOString(),
            service: 'wattwise-api',
            ...data
        };

        // Format based on environment
        if (process.env.NODE_ENV === 'production') {
            console.log(JSON.stringify(logEntry));
        } else {
            console.log(`[${level.toUpperCase()}] ${message}:`, logEntry);
        }
    }

    async storeActivity(activity) {
        try {
            // Store recent activity in cache (last 100 activities per user)
            const cacheKey = cacheService.generateUserKey(activity.userId, 'recent_activities');
            const activities = await cacheService.get(cacheKey) || [];

            activities.unshift(activity);

            // Keep only last 100 activities
            const recentActivities = activities.slice(0, 100);

            await cacheService.set(cacheKey, recentActivities, 3600); // 1 hour
        } catch (error) {
            // Don't let logging errors break the application
            loggingMiddleware.log('error', 'Failed to store activity', { message: error.message });
        }
    }

    // ─── Log Retrieval ─────────────────────────────────────────────

    async getRecentActivities(userId, limit = 20) {
        try {
            const cacheKey = cacheService.generateUserKey(userId, 'recent_activities');
            const activities = await cacheService.get(cacheKey) || [];

            return activities.slice(0, limit);
        } catch (error) {
            loggingMiddleware.log('error', 'Failed to retrieve activities', { message: error.message });
            return [];
        }
    }

    // ─── Health Check Logging ─────────────────────────────────────────────

    logHealthCheck(status, details) {
        const logData = {
            type: 'health_check',
            timestamp: new Date().toISOString(),
            status,
            ...details
        };

        loggingMiddleware.log('info', 'Health Check', logData);
    }

    logMemoryEvent({
        eventType,
        scope,
        revisionId,
        requestId,
        runId,
        threadId,
        tokenBudgetUsed,
        usedFallback,
    }) {
        const logData = {
            type: 'memory',
            eventType,
            timestamp: new Date().toISOString(),
            scope,
            revisionId,
            requestId,
            runId,
            threadId,
            tokenBudgetUsed,
            usedFallback,
        };

        loggingMiddleware.log('info', 'Memory Event', logData);
    }
}

// Singleton instance
const loggingMiddleware = new LoggingMiddleware();

module.exports = loggingMiddleware;
