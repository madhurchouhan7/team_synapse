// src/middleware/rateLimit.middleware.js
// Enhanced rate limiting with per-user and per-endpoint controls

const rateLimit = require('express-rate-limit');
const Redis = require('ioredis');

// Import the ipKeyGenerator helper from express-rate-limit
const { ipKeyGenerator } = require('express-rate-limit');

// Redis client for distributed rate limiting
let redisClient = null;

// Initialize Redis if available
try {
    redisClient = new Redis(process.env.REDIS_URL || 'redis://localhost:6379');
    redisClient.on('error', (err) => {
        console.warn('Redis connection failed, falling back to memory store:', err.message);
        redisClient = null;
    });
} catch (_error) {
    console.warn('Redis not available, using memory store for rate limiting');
}

/**
 * Create a rate limiter with Redis store if available, otherwise memory store
 */
const createRateLimiter = (options) => {
    const store = redisClient ? new RedisStore({
        client: redisClient,
    }) : undefined;

    return rateLimit({
        windowMs: options.windowMs || 15 * 60 * 1000, // 15 minutes default
        max: options.max || 100, // 100 requests default
        message: options.message || 'Too many requests, please try again later.',
        standardHeaders: true,
        legacyHeaders: false,
        store,
        keyGenerator: options.keyGenerator || ((req) => {
            // Default: use IP + user ID if authenticated
            const userId = req.user?.id || req.user?._id;
            if (userId) {
                return `user:${userId}`;
            }
            // Use the proper ipKeyGenerator helper for IPv6 safety
            return ipKeyGenerator(req);
        }),
        skip: options.skip || (() => false),
    });
};

/**
 * Redis store for express-rate-limit
 */
class RedisStore {
    constructor(options) {
        this.client = options.client;
        this.prefix = 'rl:';
    }

    async increment(key) {
        const fullKey = this.prefix + key;
        const current = await this.client.incr(fullKey);

        if (current === 1) {
            // Set expiration on first increment
            await this.client.expire(fullKey, 900); // 15 minutes
        }

        return {
            totalHits: current,
            resetTime: new Date(Date.now() + 900 * 1000),
        };
    }

    async decrement(key) {
        const fullKey = this.prefix + key;
        await this.client.decr(fullKey);
    }

    async resetKey(key) {
        const fullKey = this.prefix + key;
        await this.client.del(fullKey);
    }
}

/**
 * Rate limiters for different use cases
 */
const rateLimiters = {
    // General API rate limiting
    general: createRateLimiter({
        windowMs: 15 * 60 * 1000, // 15 minutes
        max: 200, // 200 requests per window
        message: 'Too many requests. Please try again later.',
    }),

    // Strict rate limiting for sensitive operations
    strict: createRateLimiter({
        windowMs: 15 * 60 * 1000, // 15 minutes
        max: 50, // 50 requests per window
        message: 'Too many sensitive operations. Please try again later.',
    }),

    // Authentication rate limiting
    auth: createRateLimiter({
        windowMs: 15 * 60 * 1000, // 15 minutes
        max: 10, // 10 auth attempts per window
        message: 'Too many authentication attempts. Please try again later.',
        keyGenerator: (req) => {
            // Use IP for auth attempts to prevent credential stuffing
            return `auth:${ipKeyGenerator(req)}`;
        },
    }),

    // AI/ML operations rate limiting
    ai: createRateLimiter({
        windowMs: 60 * 60 * 1000, // 1 hour
        max: 200, // 200 AI requests per hour
        message: 'Too many AI requests. Please try again later.',
    }),

    // File upload rate limiting
    upload: createRateLimiter({
        windowMs: 60 * 60 * 1000, // 1 hour
        max: 50, // 50 uploads per hour
        message: 'Too many file uploads. Please try again later.',
    }),

    // Bill fetching rate limiting
    billFetch: createRateLimiter({
        windowMs: 60 * 60 * 1000, // 1 hour
        max: 30, // 30 bill fetches per hour
        message: 'Too many bill fetch attempts. Please try again later.',
    }),
};

/**
 * Dynamic rate limiting based on user tier
 */
const dynamicRateLimit = (req, res, next) => {
    const user = req.user;

    // Define rate limits based on user tier or subscription
    const getLimitsForUser = (user) => {
        if (!user) return { max: 50, windowMs: 15 * 60 * 1000 }; // Anonymous

        // You can implement user tier logic here
        // For example: free, premium, enterprise
        const tier = user.subscriptionTier || 'free';

        switch (tier) {
            case 'enterprise':
                return { max: 1000, windowMs: 15 * 60 * 1000 };
            case 'premium':
                return { max: 500, windowMs: 15 * 60 * 1000 };
            case 'free':
            default:
                return { max: 200, windowMs: 15 * 60 * 1000 };
        }
    };

    const limits = getLimitsForUser(user);

    const limiter = createRateLimiter({
        windowMs: limits.windowMs,
        max: limits.max,
        prefix: 'rl:dynamic:',
        keyGenerator: (req) => `user:${req.user?.id || req.ip}`,
    });

    limiter(req, res, next);
};

/**
 * Rate limiting middleware factory
 */
const rateLimitMiddleware = (type) => {
    const limiter = rateLimiters[type];

    if (!limiter) {
        throw new Error(`Rate limiter type '${type}' not found`);
    }

    return limiter;
};

/**
 * Custom rate limiting for specific scenarios
 */
const customRateLimit = (options) => {
    return createRateLimiter(options);
};

/**
 * Rate limit status middleware
 * Adds rate limit headers to responses
 */
const rateLimitStatus = (req, res, next) => {
    res.on('finish', () => {
        const rateLimit = res.get('X-RateLimit-Limit');
        const rateLimitRemaining = res.get('X-RateLimit-Remaining');
        const _rateLimitReset = res.get('X-RateLimit-Reset');

        if (rateLimit) {
            console.log(`Rate limit status for ${req.ip}: ${rateLimitRemaining}/${rateLimit}`);
        }
    });

    next();
};

module.exports = {
    rateLimiters,
    rateLimitMiddleware,
    dynamicRateLimit,
    customRateLimit,
    rateLimitStatus,
    RedisStore,
};
