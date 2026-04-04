// src/services/BaseService.js
// Base service class with common business logic

class BaseService {
    constructor(repository) {
        this.repository = repository;
    }

    // ─── CRUD Operations ─────────────────────────────────────────────────────

    async create(data) {
        try {
            const document = await this.repository.create(data);
            return document;
        } catch (error) {
            throw new Error(`Failed to create ${this.repository.model.modelName}: ${error.message}`, { cause: error });
        }
    }

    async findById(id, options = {}) {
        try {
            const document = await this.repository.findById(id, options);
            
            if (!document) {
                throw new Error(`${this.repository.model.modelName} not found`);
            }
            
            return document;
        } catch (error) {
            throw new Error(`Failed to find ${this.repository.model.modelName}: ${error.message}`, { cause: error });
        }
    }

    async findOne(filter, options = {}) {
        try {
            const document = await this.repository.findOne(filter, options);
            return document;
        } catch (error) {
            throw new Error(`Failed to find ${this.repository.model.modelName}: ${error.message}`, { cause: error });
        }
    }

    async find(filter = {}, options = {}) {
        try {
            const documents = await this.repository.find(filter, options);
            return documents;
        } catch (error) {
            throw new Error(`Failed to find ${this.repository.model.modelName}s: ${error.message}`, { cause: error });
        }
    }

    async updateById(id, updateData, options = {}) {
        try {
            const document = await this.repository.updateById(id, updateData, options);
            
            if (!document) {
                throw new Error(`${this.repository.model.modelName} not found`);
            }
            
            return document;
        } catch (error) {
            throw new Error(`Failed to update ${this.repository.model.modelName}: ${error.message}`, { cause: error });
        }
    }

    async deleteById(id, options = {}) {
        try {
            const document = await this.repository.deleteById(id, options);
            
            if (!document) {
                throw new Error(`${this.repository.model.modelName} not found`);
            }
            
            return document;
        } catch (error) {
            throw new Error(`Failed to delete ${this.repository.model.modelName}: ${error.message}`, { cause: error });
        }
    }

    // ─── Pagination ─────────────────────────────────────────────────────

    async findWithPagination(filter = {}, pagination = {}, options = {}) {
        try {
            const result = await this.repository.findWithPagination(filter, pagination, options);
            return result;
        } catch (error) {
            throw new Error(`Failed to find ${this.repository.model.modelName}s with pagination: ${error.message}`, { cause: error });
        }
    }

    // ─── Validation Helpers ─────────────────────────────────────────────────

    async validateExists(id) {
        const exists = await this.repository.exists({ _id: id });
        if (!exists) {
            throw new Error(`${this.repository.model.modelName} not found`);
        }
        return true;
    }

    async validateOwnership(userId, documentId) {
        const document = await this.repository.findOne({
            _id: documentId,
            userId
        });
        
        if (!document) {
            throw new Error(`${this.repository.model.modelName} not found or access denied`);
        }
        
        return document;
    }

    // ─── Data Transformation ───────────────────────────────────────────────

    transformDocument(document, options = {}) {
        if (!document) return null;
        
        const transformed = document.toJSON ? document.toJSON() : document.toObject();
        
        if (options.excludeFields) {
            options.excludeFields.forEach(field => {
                delete transformed[field];
            });
        }
        
        if (options.includeFields) {
            const filtered = {};
            options.includeFields.forEach(field => {
                if (transformed[field] !== undefined) {
                    filtered[field] = transformed[field];
                }
            });
            return filtered;
        }
        
        return transformed;
    }

    transformDocuments(documents, options = {}) {
        return documents.map(doc => this.transformDocument(doc, options));
    }

    // ─── Error Handling ─────────────────────────────────────────────────────

    handleDatabaseError(error, operation) {
        if (error.code === 11000) {
            // Duplicate key error
            const field = Object.keys(error.keyPattern)[0];
            throw new Error(`${field} already exists`);
        }
        
        if (error.name === 'ValidationError') {
            const messages = Object.values(error.errors).map(err => err.message);
            throw new Error(`Validation failed: ${messages.join(', ')}`);
        }
        
        if (error.name === 'CastError') {
            throw new Error(`Invalid ${error.path}: ${error.value}`);
        }
        
        throw new Error(`${operation} failed: ${error.message}`);
    }

    // ─── Business Logic Helpers ─────────────────────────────────────────────

    async calculatePagination(page, limit) {
        const parsedPage = Math.max(1, parseInt(page) || 1);
        const parsedLimit = Math.min(100, Math.max(1, parseInt(limit) || 10));
        
        return {
            page: parsedPage,
            limit: parsedLimit,
            skip: (parsedPage - 1) * parsedLimit
        };
    }

    async buildSearchFilter(query, searchableFields = []) {
        if (!query || searchableFields.length === 0) return {};
        
        const searchRegex = new RegExp(query, 'i');
        const searchConditions = searchableFields.map(field => ({
            [field]: searchRegex
        }));
        
        return { $or: searchConditions };
    }

    async buildDateRangeFilter(startDate, endDate, dateField = 'createdAt') {
        const filter = {};
        
        if (startDate) {
            filter[dateField] = { $gte: new Date(startDate) };
        }
        
        if (endDate) {
            filter[dateField] = { ...filter[dateField], $lte: new Date(endDate) };
        }
        
        return filter;
    }

    // ─── Caching Helpers ───────────────────────────────────────────────────

    getCacheKey(prefix, identifier) {
        return `${prefix}:${identifier}`;
    }

    async getCachedData(cacheService, key) {
        try {
            return await cacheService.get(key);
        } catch (error) {
            console.warn('Cache get error:', error.message);
            return null;
        }
    }

    async setCachedData(cacheService, key, data, ttl = 3600) {
        try {
            await cacheService.set(key, data, ttl);
        } catch (error) {
            console.warn('Cache set error:', error.message);
        }
    }

    async invalidateCache(cacheService, pattern) {
        try {
            await cacheService.del(pattern);
        } catch (error) {
            console.warn('Cache invalidate error:', error.message);
        }
    }

    // ─── Audit Trail ───────────────────────────────────────────────────────

    async logActivity(userId, action, details = {}) {
        // This can be implemented to log user activities
        console.log(`User ${userId} performed ${action}`, details);
    }

    // ─── Data Integrity ─────────────────────────────────────────────────────

    async validateDataIntegrity(document, rules = {}) {
        const errors = [];
        
        for (const [field, rule] of Object.entries(rules)) {
            const value = document[field];
            
            if (rule.required && (!value || (Array.isArray(value) && value.length === 0))) {
                errors.push(`${field} is required`);
                continue;
            }
            
            if (rule.type && value && typeof value !== rule.type) {
                errors.push(`${field} must be of type ${rule.type}`);
                continue;
            }
            
            if (rule.min && value && value < rule.min) {
                errors.push(`${field} must be at least ${rule.min}`);
            }
            
            if (rule.max && value && value > rule.max) {
                errors.push(`${field} must be at most ${rule.max}`);
            }
            
            if (rule.enum && value && !rule.enum.includes(value)) {
                errors.push(`${field} must be one of: ${rule.enum.join(', ')}`);
            }
        }
        
        if (errors.length > 0) {
            throw new Error(`Data validation failed: ${errors.join(', ')}`);
        }
        
        return true;
    }

    // ─── Soft Delete Support ─────────────────────────────────────────────────

    async softDelete(id) {
        return this.repository.deleteById(id, { soft: true });
    }

    async restore(id) {
        return this.repository.updateById(id, { isActive: true });
    }
}

module.exports = BaseService;
