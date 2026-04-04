// src/services/CacheService.js
// Redis-based caching service with advanced features

const Redis = require('ioredis');

class CacheService {
    constructor() {
        this.client = null;
        this.isConnected = false;
        if (process.env.NODE_ENV === 'test') {
            return;
        }
        this.init();
    }

    async init() {
        try {
            this.client = new Redis(process.env.REDIS_URL || 'redis://localhost:6379', {
                retryDelayOnFailover: 100,
                maxRetriesPerRequest: 3,
                lazyConnect: true
            });

            this.client.on('connect', () => {
                console.log('✅ Redis connected');
                this.isConnected = true;
            });

            this.client.on('error', (err) => {
                console.error('❌ Redis connection error:', err.message);
                this.isConnected = false;
            });

            this.client.on('close', () => {
                console.log('🔌 Redis connection closed');
                this.isConnected = false;
            });

            await this.client.connect();
        } catch (error) {
            console.warn('⚠️ Redis not available, caching disabled:', error.message);
            this.isConnected = false;
        }
    }

    // ─── Basic Cache Operations ─────────────────────────────────────────────

    async get(key) {
        if (!this.isConnected) return null;
        
        try {
            const value = await this.client.get(key);
            return value ? JSON.parse(value) : null;
        } catch (error) {
            console.warn('Cache get error:', error.message);
            return null;
        }
    }

    async set(key, value, ttl = 3600) {
        if (!this.isConnected) return false;
        
        try {
            const serialized = JSON.stringify(value);
            await this.client.setex(key, ttl, serialized);
            return true;
        } catch (error) {
            console.warn('Cache set error:', error.message);
            return false;
        }
    }

    async del(key) {
        if (!this.isConnected) return false;
        
        try {
            await this.client.del(key);
            return true;
        } catch (error) {
            console.warn('Cache delete error:', error.message);
            return false;
        }
    }

    async exists(key) {
        if (!this.isConnected) return false;
        
        try {
            const result = await this.client.exists(key);
            return result === 1;
        } catch (error) {
            console.warn('Cache exists error:', error.message);
            return false;
        }
    }

    // ─── Advanced Cache Operations ─────────────────────────────────────────────

    async mget(keys) {
        if (!this.isConnected || keys.length === 0) return [];
        
        try {
            const values = await this.client.mget(...keys);
            return values.map(value => value ? JSON.parse(value) : null);
        } catch (error) {
            console.warn('Cache mget error:', error.message);
            return [];
        }
    }

    async mset(keyValuePairs, ttl = 3600) {
        if (!this.isConnected || keyValuePairs.length === 0) return false;
        
        try {
            const pipeline = this.client.pipeline();
            
            for (const [key, value] of keyValuePairs) {
                const serialized = JSON.stringify(value);
                pipeline.setex(key, ttl, serialized);
            }
            
            await pipeline.exec();
            return true;
        } catch (error) {
            console.warn('Cache mset error:', error.message);
            return false;
        }
    }

    async incr(key, amount = 1) {
        if (!this.isConnected) return null;
        
        try {
            return await this.client.incrby(key, amount);
        } catch (error) {
            console.warn('Cache incr error:', error.message);
            return null;
        }
    }

    async decr(key, amount = 1) {
        if (!this.isConnected) return null;
        
        try {
            return await this.client.decrby(key, amount);
        } catch (error) {
            console.warn('Cache decr error:', error.message);
            return null;
        }
    }

    // ─── Pattern-based Operations ─────────────────────────────────────────────

    async keys(pattern) {
        if (!this.isConnected) return [];
        
        try {
            return await this.client.keys(pattern);
        } catch (error) {
            console.warn('Cache keys error:', error.message);
            return [];
        }
    }

    async delPattern(pattern) {
        if (!this.isConnected) return 0;
        
        try {
            const keys = await this.client.keys(pattern);
            if (keys.length === 0) return 0;
            
            await this.client.del(...keys);
            return keys.length;
        } catch (error) {
            console.warn('Cache delPattern error:', error.message);
            return 0;
        }
    }

    // ─── Hash Operations ─────────────────────────────────────────────────────

    async hget(key, field) {
        if (!this.isConnected) return null;
        
        try {
            const value = await this.client.hget(key, field);
            return value ? JSON.parse(value) : null;
        } catch (error) {
            console.warn('Cache hget error:', error.message);
            return null;
        }
    }

    async hset(key, field, value, ttl = 3600) {
        if (!this.isConnected) return false;
        
        try {
            const serialized = JSON.stringify(value);
            await this.client.hset(key, field, serialized);
            
            if (ttl > 0) {
                await this.client.expire(key, ttl);
            }
            
            return true;
        } catch (error) {
            console.warn('Cache hset error:', error.message);
            return false;
        }
    }

    async hgetall(key) {
        if (!this.isConnected) return {};
        
        try {
            const hash = await this.client.hgetall(key);
            const result = {};
            
            for (const [field, value] of Object.entries(hash)) {
                try {
                    result[field] = JSON.parse(value);
                } catch {
                    result[field] = value;
                }
            }
            
            return result;
        } catch (error) {
            console.warn('Cache hgetall error:', error.message);
            return {};
        }
    }

    async hdel(key, field) {
        if (!this.isConnected) return false;
        
        try {
            const result = await this.client.hdel(key, field);
            return result > 0;
        } catch (error) {
            console.warn('Cache hdel error:', error.message);
            return false;
        }
    }

    // ─── List Operations ─────────────────────────────────────────────────────

    async lpush(key, value, maxLength = 100) {
        if (!this.isConnected) return false;
        
        try {
            const serialized = JSON.stringify(value);
            await this.client.lpush(key, serialized);
            
            // Trim list to max length
            await this.client.ltrim(key, 0, maxLength - 1);
            
            return true;
        } catch (error) {
            console.warn('Cache lpush error:', error.message);
            return false;
        }
    }

    async rpush(key, value, maxLength = 100) {
        if (!this.isConnected) return false;
        
        try {
            const serialized = JSON.stringify(value);
            await this.client.rpush(key, serialized);
            
            // Trim list to max length
            await this.client.ltrim(key, -maxLength, -1);
            
            return true;
        } catch (error) {
            console.warn('Cache rpush error:', error.message);
            return false;
        }
    }

    async lrange(key, start = 0, end = -1) {
        if (!this.isConnected) return [];
        
        try {
            const values = await this.client.lrange(key, start, end);
            return values.map(value => {
                try {
                    return JSON.parse(value);
                } catch {
                    return value;
                }
            });
        } catch (error) {
            console.warn('Cache lrange error:', error.message);
            return [];
        }
    }

    // ─── Set Operations ─────────────────────────────────────────────────────

    async sadd(key, value) {
        if (!this.isConnected) return false;
        
        try {
            const serialized = JSON.stringify(value);
            await this.client.sadd(key, serialized);
            return true;
        } catch (error) {
            console.warn('Cache sadd error:', error.message);
            return false;
        }
    }

    async smembers(key) {
        if (!this.isConnected) return [];
        
        try {
            const members = await this.client.smembers(key);
            return members.map(member => {
                try {
                    return JSON.parse(member);
                } catch {
                    return member;
                }
            });
        } catch (error) {
            console.warn('Cache smembers error:', error.message);
            return [];
        }
    }

    async sismember(key, value) {
        if (!this.isConnected) return false;
        
        try {
            const serialized = JSON.stringify(value);
            const result = await this.client.sismember(key, serialized);
            return result === 1;
        } catch (error) {
            console.warn('Cache sismember error:', error.message);
            return false;
        }
    }

    // ─── Utility Methods ─────────────────────────────────────────────────────

    async ttl(key) {
        if (!this.isConnected) return -1;
        
        try {
            return await this.client.ttl(key);
        } catch (error) {
            console.warn('Cache ttl error:', error.message);
            return -1;
        }
    }

    async expire(key, ttl) {
        if (!this.isConnected) return false;
        
        try {
            const result = await this.client.expire(key, ttl);
            return result === 1;
        } catch (error) {
            console.warn('Cache expire error:', error.message);
            return false;
        }
    }

    async flushdb() {
        if (!this.isConnected) return false;
        
        try {
            await this.client.flushdb();
            return true;
        } catch (error) {
            console.warn('Cache flushdb error:', error.message);
            return false;
        }
    }

    // ─── Cache Key Generation ─────────────────────────────────────────────

    generateKey(prefix, identifier, namespace = 'app') {
        return `${namespace}:${prefix}:${identifier}`;
    }

    generateUserKey(userId, prefix, _identifier = '') {
        return this.generateKey(`user:${userId}`, prefix, 'app');
    }

    generateSessionKey(sessionId, prefix) {
        return this.generateKey(`session:${sessionId}`, prefix, 'session');
    }

    generateContentKey(kind, slug = 'default', locale = 'en-IN') {
        const safeKind = String(kind || 'unknown').trim().toLowerCase();
        const safeSlug = String(slug || 'default').trim().toLowerCase();
        const safeLocale = String(locale || 'en-IN').trim().toLowerCase();
        return this.generateKey('content', `${safeKind}:${safeSlug}:${safeLocale}`, 'app');
    }

    // ─── Cache Warming and Preloading ─────────────────────────────────────────────

    async warmCache(dataLoader, keyPatterns, ttl = 3600) {
        if (!this.isConnected) return;
        
        try {
            for (const pattern of keyPatterns) {
                const data = await dataLoader(pattern);
                if (data) {
                    await this.set(pattern.key, data, ttl);
                }
            }
        } catch (error) {
            console.warn('Cache warming error:', error.message);
        }
    }

    // ─── Cache Statistics ─────────────────────────────────────────────────────

    async getStats() {
        if (!this.isConnected) return null;
        
        try {
            const info = await this.client.info('memory');
            const keyspace = await this.client.info('keyspace');
            
            return {
                connected: this.isConnected,
                memory: this.parseMemoryInfo(info),
                keyspace: this.parseKeyspaceInfo(keyspace)
            };
        } catch (error) {
            console.warn('Cache stats error:', error.message);
            return null;
        }
    }

    parseMemoryInfo(info) {
        const lines = info.split('\r\n');
        const memory = {};
        
        for (const line of lines) {
            if (line.startsWith('used_memory_human:')) {
                memory.used = line.split(':')[1];
            }
            if (line.startsWith('used_memory_peak_human:')) {
                memory.peak = line.split(':')[1];
            }
        }
        
        return memory;
    }

    parseKeyspaceInfo(info) {
        const lines = info.split('\r\n');
        const keyspace = {};
        
        for (const line of lines) {
            if (line.startsWith('db')) {
                const [db, stats] = line.split(':');
                keyspace[db] = stats;
            }
        }
        
        return keyspace;
    }

    // ─── Health Check ─────────────────────────────────────────────────────

    async healthCheck() {
        if (!this.isConnected) {
            return {
                status: 'unhealthy',
                message: 'Redis not connected'
            };
        }
        
        try {
            const pong = await this.client.ping();
            const stats = await this.getStats();
            
            return {
                status: pong === 'PONG' ? 'healthy' : 'unhealthy',
                message: pong === 'PONG' ? 'Redis responding' : 'Redis not responding',
                stats
            };
        } catch (error) {
            return {
                status: 'unhealthy',
                message: error.message
            };
        }
    }

    // ─── Graceful Shutdown ─────────────────────────────────────────────────────

    async disconnect() {
        if (this.client) {
            await this.client.disconnect();
            this.isConnected = false;
            console.log('🔌 Redis disconnected');
        }
    }
}

// Singleton instance
const cacheService = new CacheService();

module.exports = cacheService;
