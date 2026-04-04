// src/controllers/health.controller.js
// Health check endpoints for monitoring and diagnostics

const { sendSuccess } = require('../utils/ApiResponse');
const cacheService = require('../services/CacheService');

class HealthController {
    constructor() {
        this.startTime = Date.now();
        this.checks = new Map();
        this.setupHealthChecks();
    }

    setupHealthChecks() {
        // Database health check
        this.checks.set('database', {
            name: 'MongoDB',
            check: this.checkDatabase.bind(this)
        });

        // Cache health check
        this.checks.set('cache', {
            name: 'Redis',
            check: this.checkCache.bind(this)
        });

        // Memory health check
        this.checks.set('memory', {
            name: 'Memory',
            check: this.checkMemory.bind(this)
        });

        // Disk health check
        this.checks.set('disk', {
            name: 'Disk',
            check: this.checkDisk.bind(this)
        });
    }

    // ─── Basic Health Check ─────────────────────────────────────────────────

    async basic(req, res) {
        const uptime = Date.now() - this.startTime;
        const status = {
            status: 'healthy',
            timestamp: new Date().toISOString(),
            uptime: `${Math.floor(uptime / 1000)}s`,
            version: process.env.npm_package_version || '1.0.0',
            environment: process.env.NODE_ENV || 'development',
            service: 'wattwise-api'
        };

        sendSuccess(res, 200, 'Health check passed.', status);
    }

    // ─── Detailed Health Check ─────────────────────────────────────────────────

    async detailed(req, res) {
        const results = await this.runAllChecks();
        const overallStatus = this.determineOverallStatus(results);
        
        const healthReport = {
            status: overallStatus,
            timestamp: new Date().toISOString(),
            uptime: `${Math.floor((Date.now() - this.startTime) / 1000)}s`,
            version: process.env.npm_package_version || '1.0.0',
            environment: process.env.NODE_ENV || 'development',
            service: 'wattwise-api',
            checks: results,
            summary: this.generateSummary(results)
        };

        const statusCode = overallStatus === 'healthy' ? 200 : 
                          overallStatus === 'degraded' ? 200 : 503;

        res.status(statusCode).json({
            success: overallStatus !== 'unhealthy',
            message: `Health status: ${overallStatus}`,
            data: healthReport
        });
    }

    // ─── Readiness Check ─────────────────────────────────────────────────

    async readiness(req, res) {
        // Check if application is ready to serve traffic
        const criticalChecks = ['database', 'cache'];
        const results = await this.runSpecificChecks(criticalChecks);
        
        const isReady = criticalChecks.every(check => 
            results[check]?.status === 'healthy'
        );

        const status = {
            ready: isReady,
            timestamp: new Date().toISOString(),
            checks: results
        };

        const statusCode = isReady ? 200 : 503;
        
        res.status(statusCode).json({
            success: isReady,
            message: isReady ? 'Service is ready' : 'Service is not ready',
            data: status
        });
    }

    // ─── Liveness Check ─────────────────────────────────────────────────

    async liveness(req, res) {
        // Simple check if the application is alive
        const uptime = Date.now() - this.startTime;
        
        const status = {
            alive: true,
            timestamp: new Date().toISOString(),
            uptime: `${Math.floor(uptime / 1000)}s`
        };

        sendSuccess(res, 200, 'Service is alive.', status);
    }

    // ─── Health Check Implementations ─────────────────────────────────────────

    async checkDatabase() {
        try {
            const mongoose = require('mongoose');
            const state = mongoose.connection.readyState;
            
            const states = {
                0: 'disconnected',
                1: 'connected',
                2: 'connecting',
                3: 'disconnecting'
            };

            const isConnected = state === 1;
            
            // Test database operation
            if (isConnected) {
                await mongoose.connection.db.admin().ping();
            }

            return {
                status: isConnected ? 'healthy' : 'unhealthy',
                message: `Database is ${states[state]}`,
                details: {
                    state: states[state],
                    host: mongoose.connection.host,
                    name: mongoose.connection.name
                },
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                status: 'unhealthy',
                message: 'Database connection failed',
                error: error.message,
                timestamp: new Date().toISOString()
            };
        }
    }

    async checkCache() {
        try {
            const cacheStats = await cacheService.getStats();
            
            if (!cacheStats) {
                return {
                    status: 'degraded',
                    message: 'Cache service not available',
                    timestamp: new Date().toISOString()
                };
            }

            // Test cache operation
            const testKey = 'health_check_test';
            const testValue = { test: true, timestamp: Date.now() };
            
            await cacheService.set(testKey, testValue, 10);
            const retrieved = await cacheService.get(testKey);
            await cacheService.del(testKey);

            const isWorking = retrieved && retrieved.test === true;

            return {
                status: isWorking ? 'healthy' : 'unhealthy',
                message: `Cache is ${isWorking ? 'working' : 'not working'}`,
                details: cacheStats,
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                status: 'unhealthy',
                message: 'Cache check failed',
                error: error.message,
                timestamp: new Date().toISOString()
            };
        }
    }

    async checkMemory() {
        try {
            const memUsage = process.memoryUsage();
            const totalMemory = require('os').totalmem();
            const freeMemory = require('os').freemem();
            
            const heapUsedMB = Math.round(memUsage.heapUsed / 1024 / 1024);
            const heapTotalMB = Math.round(memUsage.heapTotal / 1024 / 1024);
            const systemUsagePercent = ((totalMemory - freeMemory) / totalMemory) * 100;
            
            // Memory thresholds
            const heapThreshold = 500; // 500MB
            const systemThreshold = 90; // 90%
            
            let status = 'healthy';
            let message = 'Memory usage is normal';
            
            if (heapUsedMB > heapThreshold * 1.5) {
                status = 'unhealthy';
                message = 'High memory usage';
            } else if (heapUsedMB > heapThreshold || systemUsagePercent > systemThreshold) {
                status = 'degraded';
                message = 'Elevated memory usage';
            }

            return {
                status,
                message,
                details: {
                    heap: {
                        used: `${heapUsedMB}MB`,
                        total: `${heapTotalMB}MB`,
                        percentage: Math.round((heapUsedMB / heapTotalMB) * 100)
                    },
                    system: {
                        total: `${Math.round(totalMemory / 1024 / 1024)}MB`,
                        free: `${Math.round(freeMemory / 1024 / 1024)}MB`,
                        usagePercent: Math.round(systemUsagePercent)
                    },
                    rss: `${Math.round(memUsage.rss / 1024 / 1024)}MB`,
                    external: `${Math.round(memUsage.external / 1024 / 1024)}MB`
                },
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                status: 'unhealthy',
                message: 'Memory check failed',
                error: error.message,
                timestamp: new Date().toISOString()
            };
        }
    }

    async checkDisk() {
        try {
            // Check disk space for current directory
            // Note: fs.stat(process.cwd()) was here but unused; 
            // in production, you'd use a proper disk space library.
            
            // Simple disk check (in production, you'd use a proper disk space library)
            const mockDiskUsage = {
                total: 1000000, // Mock values
                used: 500000,
                free: 500000
            };
            
            const usagePercent = (mockDiskUsage.used / mockDiskUsage.total) * 100;
            
            let status = 'healthy';
            let message = 'Disk usage is normal';
            
            if (usagePercent > 90) {
                status = 'unhealthy';
                message = 'Low disk space';
            } else if (usagePercent > 80) {
                status = 'degraded';
                message = 'Elevated disk usage';
            }

            return {
                status,
                message,
                details: {
                    total: `${Math.round(mockDiskUsage.total / 1024 / 1024)}MB`,
                    used: `${Math.round(mockDiskUsage.used / 1024 / 1024)}MB`,
                    free: `${Math.round(mockDiskUsage.free / 1024 / 1024)}MB`,
                    usagePercent: Math.round(usagePercent)
                },
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                status: 'unhealthy',
                message: 'Disk check failed',
                error: error.message,
                timestamp: new Date().toISOString()
            };
        }
    }

    // ─── Utility Methods ─────────────────────────────────────────────────

    async runAllChecks() {
        const results = {};
        
        for (const [key, check] of this.checks) {
            try {
                results[key] = await check.check();
            } catch (error) {
                results[key] = {
                    status: 'unhealthy',
                    message: 'Check failed',
                    error: error.message,
                    timestamp: new Date().toISOString()
                };
            }
        }
        
        return results;
    }

    async runSpecificChecks(checkNames) {
        const results = {};
        
        for (const name of checkNames) {
            if (this.checks.has(name)) {
                try {
                    results[name] = await this.checks.get(name).check();
                } catch (error) {
                    results[name] = {
                        status: 'unhealthy',
                        message: 'Check failed',
                        error: error.message,
                        timestamp: new Date().toISOString()
                    };
                }
            }
        }
        
        return results;
    }

    determineOverallStatus(results) {
        const statuses = Object.values(results).map(r => r.status);
        
        if (statuses.includes('unhealthy')) {
            return 'unhealthy';
        }
        
        if (statuses.includes('degraded')) {
            return 'degraded';
        }
        
        return 'healthy';
    }

    generateSummary(results) {
        const summary = {
            total: Object.keys(results).length,
            healthy: 0,
            degraded: 0,
            unhealthy: 0
        };
        
        Object.values(results).forEach(result => {
            summary[result.status]++;
        });
        
        return summary;
    }

    // ─── Metrics Endpoint ─────────────────────────────────────────────────

    async metrics(req, res) {
        try {
            const metrics = {
                timestamp: new Date().toISOString(),
                uptime: Date.now() - this.startTime,
                memory: process.memoryUsage(),
                cpu: process.cpuUsage(),
                version: process.env.npm_package_version || '1.0.0',
                environment: process.env.NODE_ENV || 'development',
                nodeVersion: process.version,
                platform: process.platform,
                arch: process.arch
            };

            // Add custom metrics
            metrics.custom = {
                activeConnections: this.getActiveConnections(),
                requestsPerMinute: this.getRequestsPerMinute(),
                errorRate: this.getErrorRate()
            };

            sendSuccess(res, 200, 'Metrics retrieved successfully.', metrics);
        } catch (error) {
            res.status(500).json({
                success: false,
                message: 'Failed to retrieve metrics',
                error: error.message
            });
        }
    }

    getActiveConnections() {
        // This would be implemented based on your connection tracking
        return 0;
    }

    getRequestsPerMinute() {
        // This would be implemented based on your request tracking
        return 0;
    }

    getErrorRate() {
        // This would be implemented based on your error tracking
        return 0;
    }
}

// Singleton instance
const healthController = new HealthController();

module.exports = healthController;
