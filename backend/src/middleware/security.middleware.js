// src/middleware/security.middleware.js
// Security middleware for input sanitization and additional protection

const ApiError = require('../utils/ApiError');

/**
 * Input sanitization middleware
 * Removes potentially dangerous characters and normalizes input
 */
const sanitizeInput = (req, res, next) => {
    const sanitizeString = (str) => {
        if (typeof str !== 'string') return str;
        
        // Remove potential XSS characters
        return str
            .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
            .replace(/<iframe\b[^<]*(?:(?!<\/iframe>)<[^<]*)*<\/iframe>/gi, '')
            .replace(/javascript:/gi, '')
            .replace(/on\w+\s*=/gi, '')
            .trim();
    };

    const sanitizeObject = (obj) => {
        if (obj === null || obj === undefined) return obj;
        
        if (typeof obj === 'string') {
            return sanitizeString(obj);
        }
        
        if (Array.isArray(obj)) {
            return obj.map(item => sanitizeObject(item));
        }
        
        if (typeof obj === 'object') {
            const sanitized = {};
            for (const [key, value] of Object.entries(obj)) {
                sanitized[key] = sanitizeObject(value);
            }
            return sanitized;
        }
        
        return obj;
    };

    // Sanitize request body, query, and params
    if (req.body) {
        req.body = sanitizeObject(req.body);
    }
    
    if (req.query) {
        req.query = sanitizeObject(req.query);
    }
    
    if (req.params) {
        req.params = sanitizeObject(req.params);
    }

    next();
};

/**
 * NoSQL injection prevention middleware
 * Validates MongoDB queries against injection patterns
 */
const preventNoSQLInjection = (req, res, next) => {
    const checkForInjection = (obj) => {
        if (obj === null || obj === undefined) return false;
        
        if (typeof obj === 'string') {
            // Check for common NoSQL injection patterns
            const injectionPatterns = [
                /\$where/i,
                /\$ne/i,
                /\$in/i,
                /\$nin/i,
                /\$exists/i,
                /\$regex/i,
                /\$expr/i,
                /\$jsonSchema/i,
                /\{.*\$.*\}/,
            ];
            
            return injectionPatterns.some(pattern => pattern.test(obj));
        }
        
        if (Array.isArray(obj)) {
            return obj.some(item => checkForInjection(item));
        }
        
        if (typeof obj === 'object') {
            return Object.values(obj).some(value => checkForInjection(value));
        }
        
        return false;
    };

    // Check request body for injection patterns
    if (req.body && checkForInjection(req.body)) {
        return next(new ApiError(400, 'Invalid input detected'));
    }

    next();
};

/**
 * Content Security Policy middleware
 * Adds CSP headers to prevent XSS and other injection attacks
 */
const contentSecurityPolicy = (req, res, next) => {
    const csp = [
        "default-src 'self'",
        "script-src 'self' 'unsafe-inline' https://apis.google.com",
        "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
        "font-src 'self' https://fonts.gstatic.com",
        "img-src 'self' data: https:",
        "connect-src 'self' https://*.googleapis.com https://*.firebaseio.com",
        "frame-src 'none'",
        "object-src 'none'",
    ].join('; ');

    res.setHeader('Content-Security-Policy', csp);
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-Frame-Options', 'DENY');
    res.setHeader('X-XSS-Protection', '1; mode=block');
    res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');

    next();
};

/**
 * Request size limiter for specific endpoints
 * Prevents large payload attacks
 */
const requestSizeLimiter = (maxSize = '10mb') => {
    return (req, res, next) => {
        const contentLength = req.get('content-length');
        
        if (contentLength) {
            const sizeInBytes = parseInt(contentLength);
            const maxSizeInBytes = parseSize(maxSize);
            
            if (sizeInBytes > maxSizeInBytes) {
                return next(new ApiError(413, 'Request entity too large'));
            }
        }
        
        next();
    };
};

/**
 * Helper function to parse size strings (e.g., '10mb' -> bytes)
 */
const parseSize = (sizeStr) => {
    const units = {
        'b': 1,
        'kb': 1024,
        'mb': 1024 * 1024,
        'gb': 1024 * 1024 * 1024,
    };
    
    const match = sizeStr.toLowerCase().match(/^(\d+)(b|kb|mb|gb)$/);
    if (!match) return 0;
    
    const [, size, unit] = match;
    return parseInt(size) * (units[unit] || 1);
};

/**
 * API key validation for external services
 */
const validateApiKey = (req, res, next) => {
    const apiKey = req.get('X-API-Key');
    const validApiKeys = process.env.VALID_API_KEYS?.split(',') || [];
    
    // Skip validation for internal requests or if no API keys are configured
    if (!apiKey || validApiKeys.length === 0) {
        return next();
    }
    
    if (!validApiKeys.includes(apiKey)) {
        return next(new ApiError(401, 'Invalid API key'));
    }
    
    next();
};

module.exports = {
    sanitizeInput,
    preventNoSQLInjection,
    contentSecurityPolicy,
    requestSizeLimiter,
    validateApiKey,
};
