// src/repositories/UserRepository.js
// User-specific repository with custom methods

const BaseRepository = require('./BaseRepository');
const User = require('../models/User.model');

class UserRepository extends BaseRepository {
    constructor() {
        super(User);
    }

    // ─── User-Specific Methods ─────────────────────────────────────────────────

    // Override Base methods to never fetch huge blobs by default
    async findById(id, options = {}) {
        if (!options.select) {
            options.select = '-bills -activePlan -deviceTokens';
        }
        return super.findById(id, options);
    }

    async findOne(filter, options = {}) {
        if (!options.select) {
            options.select = '-bills -activePlan -deviceTokens';
        }
        return super.findOne(filter, options);
    }

    async updateById(id, updateData, options = {}) {
        if (!options.select) {
            options.select = '-bills -activePlan -deviceTokens';
        }
        // Force Mongoose's findByIdAndUpdate config to returnDocument: 'after' to fix deprecation warning
        options.returnDocument = 'after';
        return super.updateById(id, updateData, options);
    }

    async findByFirebaseUid(firebaseUid) {
        return this.findOne({ firebaseUid, isActive: true });
    }

    async findByEmail(email) {
        return this.findOne({ email: email.toLowerCase(), isActive: true });
    }

    async getPremiumUsers() {
        return this.find({
            subscriptionTier: { $in: ['premium', 'enterprise'] },
            isActive: true
        });
    }

    async getUsersByTier(tier) {
        return this.find({
            subscriptionTier: tier,
            isActive: true
        });
    }

    async getActiveUsers() {
        return this.find({
            isActive: true,
            isVerified: true
        });
    }

    async getRecentUsers(days = 30) {
        const dateThreshold = new Date();
        dateThreshold.setDate(dateThreshold.getDate() - days);

        return this.find({
            createdAt: { $gte: dateThreshold },
            isActive: true
        }).sort({ createdAt: -1 });
    }

    async getUserStats() {
        const stats = await this.aggregate([
            { $match: { isActive: true } },
            {
                $group: {
                    _id: null,
                    totalUsers: { $sum: 1 },
                    premiumUsers: {
                        $sum: {
                            $cond: [
                                { $in: ['$subscriptionTier', ['premium', 'enterprise']] },
                                1,
                                0
                            ]
                        }
                    },
                    verifiedUsers: {
                        $sum: {
                            $cond: ['$isVerified', 1, 0]
                        }
                    },
                    averageBudget: { $avg: '$monthlyBudget' },
                    totalBudget: { $sum: '$monthlyBudget' }
                }
            },
            {
                $project: {
                    _id: 0,
                    totalUsers: 1,
                    premiumUsers: 1,
                    verifiedUsers: 1,
                    averageBudget: { $round: ['$averageBudget', 2] },
                    totalBudget: 1,
                    premiumPercentage: {
                        $round: [
                            { $multiply: [{ $divide: ['$premiumUsers', '$totalUsers'] }, 100] },
                            2
                        ]
                    },
                    verifiedPercentage: {
                        $round: [
                            { $multiply: [{ $divide: ['$verifiedUsers', '$totalUsers'] }, 100] },
                            2
                        ]
                    }
                }
            }
        ]);

        return stats[0] || {
            totalUsers: 0,
            premiumUsers: 0,
            verifiedUsers: 0,
            averageBudget: 0,
            totalBudget: 0,
            premiumPercentage: 0,
            verifiedPercentage: 0
        };
    }

    async getUsersWithOnboardingStatus() {
        return this.aggregate([
            { $match: { isActive: true } },
            {
                $group: {
                    _id: '$onboardingCompleted',
                    count: { $sum: 1 }
                }
            },
            {
                $project: {
                    _id: 0,
                    onboardingCompleted: '$_id',
                    count: 1,
                    percentage: { $multiply: [{ $divide: ['$count', 100] }, 100] }
                }
            }
        ]);
    }

    async updateSubscription(userId, tier, expiresAt) {
        return this.updateById(userId, {
            subscriptionTier: tier,
            subscriptionExpiresAt: expiresAt
        });
    }

    async addDeviceToken(userId, token, platform = 'unknown') {
        const newToken = {
            token,
            platform,
            lastSeenAt: new Date(),
            isActive: true,
        };

        // First remove the token if it exists (upsert logic), then push and slice to keep only the last 5 tokens
        await this.model.updateOne(
            { _id: userId },
            { $pull: { deviceTokens: { token } } }
        );

        return this.model.findByIdAndUpdate(
            userId,
            {
                $push: {
                    deviceTokens: {
                        $each: [newToken],
                        $sort: { lastSeenAt: -1 },
                        $slice: 5
                    }
                }
            },
            { returnDocument: 'after', select: '-bills -activePlan -deviceTokens' }
        );
    }

    async removeDeviceToken(userId, token) {
        return this.model.findByIdAndUpdate(
            userId,
            { $pull: { deviceTokens: { token } } },
            { returnDocument: 'after', select: '-bills -activePlan -deviceTokens' }
        );
    }

    async updateLastLogin(userId) {
        return this.updateById(userId, {
            lastLoginAt: new Date()
        });
    }

    async searchUsers(query, options = {}) {
        const searchRegex = new RegExp(query, 'i');
        const searchFilter = {
            isActive: true,
            $or: [
                { name: searchRegex },
                { email: searchRegex }
            ]
        };

        return this.findWithPagination(searchFilter, options.pagination, {
            sort: { name: 1 },
            select: 'name email subscriptionTier createdAt lastLoginAt'
        });
    }

    async getUsersBySubscriptionStatus() {
        return this.aggregate([
            { $match: { isActive: true } },
            {
                $group: {
                    _id: {
                        tier: '$subscriptionTier',
                        isActive: {
                            $cond: [
                                {
                                    $or: [
                                        { $eq: ['$subscriptionExpiresAt', null] },
                                        { $gt: ['$subscriptionExpiresAt', new Date()] }
                                    ]
                                },
                                'active',
                                'expired'
                            ]
                        }
                    },
                    count: { $sum: 1 }
                }
            },
            {
                $group: {
                    _id: '$_id.tier',
                    active: {
                        $sum: {
                            $cond: [{ $eq: ['$_id.isActive', 'active'] }, '$count', 0]
                        }
                    },
                    expired: {
                        $sum: {
                            $cond: [{ $eq: ['$_id.isActive', 'expired'] }, '$count', 0]
                        }
                    }
                }
            },
            {
                $project: {
                    tier: '$_id',
                    active: 1,
                    expired: 1,
                    total: { $add: ['$active', '$expired'] }
                }
            }
        ]);
    }

    async softDeleteUser(userId) {
        return this.updateById(userId, {
            isActive: false,
            deviceTokens: []
        });
    }

    async restoreUser(userId) {
        return this.updateById(userId, {
            isActive: true
        });
    }
}

module.exports = UserRepository;
