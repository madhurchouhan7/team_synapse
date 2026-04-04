// src/repositories/BaseRepository.js
// Base repository class with common database operations

class BaseRepository {
    constructor(model) {
        this.model = model;
    }

    // ─── CRUD Operations ─────────────────────────────────────────────────────

    async create(data) {
        try {
            const document = await this.model.create(data);
            return document;
        } catch (error) {
            throw new Error(`Failed to create ${this.model.modelName}: ${error.message}`, { cause: error });
        }
    }

    async findById(id, options = {}) {
        try {
            const query = this.model.findById(id);
            
            if (options.populate) {
                query.populate(options.populate);
            }
            
            if (options.select) {
                query.select(options.select);
            }
            
            return await query;
        } catch (error) {
            throw new Error(`Failed to find ${this.model.modelName} by ID: ${error.message}`, { cause: error });
        }
    }

    async findOne(filter, options = {}) {
        try {
            const query = this.model.findOne(filter);
            
            if (options.populate) {
                query.populate(options.populate);
            }
            
            if (options.select) {
                query.select(options.select);
            }
            
            if (options.sort) {
                query.sort(options.sort);
            }
            
            return await query;
        } catch (error) {
            throw new Error(`Failed to find ${this.model.modelName}: ${error.message}`, { cause: error });
        }
    }

    async find(filter = {}, options = {}) {
        try {
            const query = this.model.find(filter);
            
            if (options.populate) {
                query.populate(options.populate);
            }
            
            if (options.select) {
                query.select(options.select);
            }
            
            if (options.sort) {
                query.sort(options.sort);
            }
            
            if (options.limit) {
                query.limit(options.limit);
            }
            
            if (options.skip) {
                query.skip(options.skip);
            }
            
            return await query;
        } catch (error) {
            throw new Error(`Failed to find ${this.model.modelName}s: ${error.message}`, { cause: error });
        }
    }

    async updateById(id, updateData, options = {}) {
        try {
            const query = this.model.findByIdAndUpdate(
                id,
                updateData,
                {
                    returnDocument: 'after',
                    runValidators: true,
                    ...options
                }
            );
            
            if (options.populate) {
                query.populate(options.populate);
            }
            
            if (options.select) {
                query.select(options.select);
            }
            
            return await query;
        } catch (error) {
            throw new Error(`Failed to update ${this.model.modelName}: ${error.message}`, { cause: error });
        }
    }

    async updateOne(filter, updateData, options = {}) {
        try {
            return await this.model.updateOne(filter, updateData, {
                runValidators: true,
                ...options
            });
        } catch (error) {
            throw new Error(`Failed to update ${this.model.modelName}: ${error.message}`, { cause: error });
        }
    }

    async updateMany(filter, updateData, options = {}) {
        try {
            return await this.model.updateMany(filter, updateData, {
                runValidators: true,
                ...options
            });
        } catch (error) {
            throw new Error(`Failed to update ${this.model.modelName}s: ${error.message}`, { cause: error });
        }
    }

    async deleteById(id, options = {}) {
        try {
            if (options.soft) {
                return await this.updateById(id, { isActive: false });
            }
            return await this.model.findByIdAndDelete(id);
        } catch (error) {
            throw new Error(`Failed to delete ${this.model.modelName}: ${error.message}`, { cause: error });
        }
    }

    async deleteOne(filter, options = {}) {
        try {
            if (options.soft) {
                return await this.updateOne(filter, { isActive: false });
            }
            return await this.model.deleteOne(filter);
        } catch (error) {
            throw new Error(`Failed to delete ${this.model.modelName}: ${error.message}`, { cause: error });
        }
    }

    async deleteMany(filter, options = {}) {
        try {
            if (options.soft) {
                return await this.updateMany(filter, { isActive: false });
            }
            return await this.model.deleteMany(filter);
        } catch (error) {
            throw new Error(`Failed to delete ${this.model.modelName}s: ${error.message}`, { cause: error });
        }
    }

    // ─── Aggregation Operations ─────────────────────────────────────────────────

    async aggregate(pipeline) {
        try {
            return await this.model.aggregate(pipeline);
        } catch (error) {
            throw new Error(`Failed to aggregate ${this.model.modelName}: ${error.message}`, { cause: error });
        }
    }

    async count(filter = {}) {
        try {
            return await this.model.countDocuments(filter);
        } catch (error) {
            throw new Error(`Failed to count ${this.model.modelName}s: ${error.message}`, { cause: error });
        }
    }

    async distinct(field, filter = {}) {
        try {
            return await this.model.distinct(field, filter);
        } catch (error) {
            throw new Error(`Failed to get distinct ${field} values: ${error.message}`, { cause: error });
        }
    }

    // ─── Pagination Helper ─────────────────────────────────────────────────

    async findWithPagination(filter = {}, pagination = {}, options = {}) {
        const { page = 1, limit = 10 } = pagination;
        const skip = (page - 1) * limit;

        try {
            const [data, total] = await Promise.all([
                this.find(filter, {
                    ...options,
                    skip,
                    limit
                }),
                this.count(filter)
            ]);

            return {
                data,
                pagination: {
                    page,
                    limit,
                    total,
                    pages: Math.ceil(total / limit),
                    hasNext: page * limit < total,
                    hasPrev: page > 1
                }
            };
        } catch (error) {
            throw new Error(`Failed to find ${this.model.modelName}s with pagination: ${error.message}`, { cause: error });
        }
    }

    // ─── Bulk Operations ─────────────────────────────────────────────────────

    async bulkCreate(dataArray) {
        try {
            return await this.model.insertMany(dataArray);
        } catch (error) {
            throw new Error(`Failed to bulk create ${this.model.modelName}s: ${error.message}`, { cause: error });
        }
    }

    async bulkUpdate(operations) {
        try {
            const bulkOps = operations.map(op => ({
                updateOne: {
                    filter: op.filter,
                    update: op.update,
                    upsert: op.upsert || false
                }
            }));

            return await this.model.bulkWrite(bulkOps);
        } catch (error) {
            throw new Error(`Failed to bulk update ${this.model.modelName}s: ${error.message}`, { cause: error });
        }
    }

    // ─── Utility Methods ─────────────────────────────────────────────────────

    async exists(filter) {
        try {
            return await this.model.exists(filter);
        } catch (error) {
            throw new Error(`Failed to check if ${this.model.modelName} exists: ${error.message}`, { cause: error });
        }
    }

    async findOneOrCreate(filter, data) {
        try {
            let document = await this.findOne(filter);
            
            if (!document) {
                document = await this.create(data);
            }
            
            return document;
        } catch (error) {
            throw new Error(`Failed to find or create ${this.model.modelName}: ${error.message}`, { cause: error });
        }
    }

    async updateOrCreate(filter, updateData, _createData = {}) {
        try {
            const document = await this.updateOne(filter, updateData, { upsert: true });
            
            if (document.upsertedId) {
                // Document was created, fetch it
                return await this.findById(document.upsertedId);
            }
            
            // Document was updated, fetch it
            return await this.findOne(filter);
        } catch (error) {
            throw new Error(`Failed to update or create ${this.model.modelName}: ${error.message}`, { cause: error });
        }
    }
}

module.exports = BaseRepository;
