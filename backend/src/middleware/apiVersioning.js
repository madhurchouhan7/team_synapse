// src/middleware/apiVersioning.js
// API versioning middleware for backward compatibility

const ApiError = require('../utils/ApiError');

class ApiVersioning {
    constructor() {
        this.supportedVersions = ['v1', 'v2'];
        this.defaultVersion = 'v1';
        this.deprecatedVersions = [];
        this.versionHandlers = new Map();
    }

    // ─── Version Detection ─────────────────────────────────────────────────────

    getVersionFromRequest(req) {
        // Try to get version from header first
        const headerVersion = req.get('API-Version');
        if (headerVersion && apiVersioning.supportedVersions.includes(headerVersion)) {
            return headerVersion;
        }

        // Try to get version from URL path
        const pathMatch = req.path.match(/^\/api\/([^/]+)/);
        if (pathMatch && apiVersioning.supportedVersions.includes(pathMatch[1])) {
            return pathMatch[1];
        }

        // Try to get version from query parameter
        const queryVersion = req.query.version;
        if (queryVersion && apiVersioning.supportedVersions.includes(queryVersion)) {
            return queryVersion;
        }

        // Return default version
        return apiVersioning.defaultVersion;
    }

    // ─── Version Validation ─────────────────────────────────────────────────────

    validateVersion(version) {
        if (!this.supportedVersions.includes(version)) {
            if (this.deprecatedVersions.includes(version)) {
                throw new ApiError(
                    410,
                    `API version ${version} is deprecated. Please use ${this.defaultVersion} or later.`
                );
            } else {
                throw new ApiError(
                    400,
                    `Unsupported API version ${version}. Supported versions: ${this.supportedVersions.join(', ')}`
                );
            }
        }
        return true;
    }

    // ─── Version Middleware ─────────────────────────────────────────────────────

    versionMiddleware() {
        return (req, res, next) => {
            try {
                const version = apiVersioning.getVersionFromRequest(req);
                apiVersioning.validateVersion(version);

                // Add version to request object
                req.apiVersion = version;

                // Add version headers
                res.setHeader('API-Version', version);
                res.setHeader('API-Supported-Versions', apiVersioning.supportedVersions.join(', '));
                res.setHeader('API-Default-Version', apiVersioning.defaultVersion);

                // Add deprecation warning if needed
                if (apiVersioning.deprecatedVersions.includes(version)) {
                    res.setHeader('Deprecation', 'true');
                    res.setHeader('Sunset', new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toUTCString());
                }

                next();
            } catch (error) {
                next(error);
            }
        };
    }

    // ─── Route Versioning ─────────────────────────────────────────────────────

    versionRoute(version, handler) {
        apiVersioning.versionHandlers.set(version, handler);

        return (req, res, next) => {
            const version = req.apiVersion || this.defaultVersion;
            const handler = apiVersioning.versionHandlers.get(version);

            if (handler) {
                return handler(req, res, next);
            }

            // Fallback to default version handler
            const defaultHandler = apiVersioning.versionHandlers.get(apiVersioning.defaultVersion);
            if (defaultHandler) {
                return defaultHandler(req, res, next);
            }

            next(new ApiError(404, 'Route not found for this API version'));
        };
    }

    // ─── Response Versioning ─────────────────────────────────────────────────────

    versionResponse(version, data) {
        // Transform response based on version
        switch (version) {
            case 'v1':
                return apiVersioning.transformV1Response(data);
            case 'v2':
                return apiVersioning.transformV2Response(data);
            default:
                return data;
        }
    }

    transformV1Response(data) {
        // V1 response format (legacy)
        if (data && typeof data === 'object') {
            // Remove V2 specific fields
            const { meta: _meta, links: _links, ...v1Data } = data;
            return v1Data;
        }
        return data;
    }

    transformV2Response(data) {
        // V2 response format (enhanced)
        if (data && typeof data === 'object') {
            return {
                ...data,
                meta: {
                    version: 'v2',
                    timestamp: new Date().toISOString(),
                    ...data.meta
                },
                links: {
                    self: apiVersioning.generateSelfLink(),
                    ...data.links
                }
            };
        }
        return data;
    }

    generateSelfLink() {
        // Generate self link based on current request
        return '/api/v2';
    }

    // ─── Version Deprecation ─────────────────────────────────────────────────────

    deprecateVersion(version, sunsetDate) {
        if (!this.supportedVersions.includes(version)) {
            throw new Error(`Cannot deprecate unsupported version: ${version}`);
        }

        apiVersioning.deprecatedVersions.push(version);

        // Remove from supported versions after sunset date
        if (sunsetDate) {
            setTimeout(() => {
                const index = apiVersioning.supportedVersions.indexOf(version);
                if (index > -1) {
                    apiVersioning.supportedVersions.splice(index, 1);
                }
            }, new Date(sunsetDate) - new Date());
        }
    }

    // ─── Version Migration ─────────────────────────────────────────────────────

    migrateData(fromVersion, toVersion, data) {
        // Migrate data structure between versions
        switch (fromVersion) {
            case 'v1':
                return apiVersioning.migrateFromV1(toVersion, data);
            default:
                return data;
        }
    }

    migrateFromV1(toVersion, data) {
        // Migrate V1 data to newer versions
        if (toVersion === 'v2') {
            return apiVersioning.migrateV1ToV2(data);
        }
        return data;
    }

    migrateV1ToV2(data) {
        // Specific migration logic from V1 to V2
        if (data && typeof data === 'object') {
            const migrated = { ...data };

            // Add V2 specific fields
            if (data.createdAt) {
                migrated.created_at = data.createdAt;
                delete migrated.createdAt;
            }

            if (data.updatedAt) {
                migrated.updated_at = data.updatedAt;
                delete migrated.updatedAt;
            }

            return migrated;
        }
        return data;
    }

    // ─── Version Documentation ─────────────────────────────────────────────────────

    getVersionInfo() {
        return {
            current: this.defaultVersion,
            supported: this.supportedVersions,
            deprecated: this.deprecatedVersions,
            migrationPaths: this.getMigrationPaths()
        };
    }

    getMigrationPaths() {
        const paths = {};

        for (const version of apiVersioning.supportedVersions) {
            if (version !== this.defaultVersion) {
                paths[version] = {
                    to: this.defaultVersion,
                    description: `Migrate from ${version} to ${this.defaultVersion}`
                };
            }
        }

        return paths;
    }

    // ─── Version Testing ─────────────────────────────────────────────────────

    testVersion(version) {
        return {
            supported: this.supportedVersions.includes(version),
            deprecated: this.deprecatedVersions.includes(version),
            default: version === this.defaultVersion
        };
    }

    // ─── Version Statistics ─────────────────────────────────────────────────────

    getVersionStats() {
        return {
            totalVersions: this.supportedVersions.length,
            deprecatedVersions: this.deprecatedVersions.length,
            defaultVersion: this.defaultVersion,
            latestVersion: apiVersioning.supportedVersions[apiVersioning.supportedVersions.length - 1]
        };
    }
}

// Singleton instance
const apiVersioning = new ApiVersioning();

module.exports = apiVersioning;
