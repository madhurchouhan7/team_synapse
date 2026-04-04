// src/repositories/ApplianceRepository.js
// Appliance-specific repository with custom methods

const BaseRepository = require('./BaseRepository');
const Appliance = require('../models/Appliance.model');

class ApplianceRepository extends BaseRepository {
    constructor() {
        super(Appliance);
    }

    // ─── Appliance-Specific Methods ───────────────────────────────────────────────

    async getByCategory(userId, category) {
        return this.find({
            userId,
            category,
            isActive: true
        });
    }

    async getByUsageLevel(userId, usageLevel) {
        return this.find({
            userId,
            usageLevel,
            isActive: true
        });
    }

    async getTotalConsumption(userId) {
        const result = await this.aggregate([
            { $match: { userId, isActive: true } },
            {
                $group: {
                    _id: null,
                    totalDailyConsumption: {
                        $sum: { $multiply: ['$wattage', '$usageHoursPerDay', '$count', 0.001] }
                    },
                    totalMonthlyConsumption: {
                        $sum: { $multiply: ['$wattage', '$usageHoursPerDay', '$count', 30, 0.001] }
                    },
                    totalAppliances: { $sum: '$count' },
                    averageWattage: { $avg: '$wattage' },
                    averageUsageHours: { $avg: '$usageHoursPerDay' }
                }
            }
        ]);

        return result[0] || {
            totalDailyConsumption: 0,
            totalMonthlyConsumption: 0,
            totalAppliances: 0,
            averageWattage: 0,
            averageUsageHours: 0
        };
    }

    async getConsumptionByCategory(userId) {
        return this.aggregate([
            { $match: { userId, isActive: true } },
            {
                $group: {
                    _id: '$category',
                    count: { $sum: '$count' },
                    totalWattage: { $sum: { $multiply: ['$wattage', '$count'] } },
                    totalDailyConsumption: {
                        $sum: { $multiply: ['$wattage', '$usageHoursPerDay', '$count', 0.001] }
                    },
                    averageWattage: { $avg: '$wattage' },
                    appliances: { $push: '$$ROOT' }
                }
            },
            {
                $project: {
                    category: '$_id',
                    count: 1,
                    totalWattage: 1,
                    totalDailyConsumption: 1,
                    averageWattage: 1,
                    appliances: { $slice: ['$appliances', 5] } // Limit to 5 examples
                }
            },
            { $sort: { totalDailyConsumption: -1 } }
        ]);
    }

    async getConsumptionByUsageLevel(userId) {
        return this.aggregate([
            { $match: { userId, isActive: true } },
            {
                $group: {
                    _id: '$usageLevel',
                    count: { $sum: '$count' },
                    totalWattage: { $sum: { $multiply: ['$wattage', '$count'] } },
                    totalDailyConsumption: {
                        $sum: { $multiply: ['$wattage', '$usageHoursPerDay', '$count', 0.001] }
                    }
                }
            },
            {
                $project: {
                    usageLevel: '$_id',
                    count: 1,
                    totalWattage: 1,
                    totalDailyConsumption: 1,
                    averageDailyConsumption: {
                        $divide: ['$totalDailyConsumption', '$count']
                    }
                }
            },
            { $sort: { usageLevel: 1 } }
        ]);
    }

    async getHighConsumptionAppliances(userId, limit = 10) {
        return this.find(
            { userId, isActive: true },
            {
                sort: { dailyConsumption: -1 },
                limit,
                select: 'title category wattage usageHoursPerDay count dailyConsumption'
            }
        );
    }

    async getApplianceEfficiencyReport(userId) {
        return this.aggregate([
            { $match: { userId, isActive: true } },
            {
                $addFields: {
                    efficiencyScore: {
                        $cond: [
                            { $eq: ['$starRating', '5'] },
                            100,
                            {
                                $cond: [
                                    { $eq: ['$starRating', '4'] },
                                    80,
                                    {
                                        $cond: [
                                            { $eq: ['$starRating', '3'] },
                                            60,
                                            {
                                                $cond: [
                                                    { $eq: ['$starRating', '2'] },
                                                    40,
                                                    20
                                                ]
                                            }
                                        ]
                                    }
                                ]
                            }
                        ]
                    },
                    potentialSavings: {
                        $multiply: [
                            { $divide: [{ $subtract: [100, '$efficiencyScore'] }, 100] },
                            { $multiply: ['$wattage', '$usageHoursPerDay', '$count', 30, 0.001] }
                        ]
                    }
                }
            },
            {
                $group: {
                    _id: null,
                    totalAppliances: { $sum: '$count' },
                    averageEfficiency: { $avg: '$efficiencyScore' },
                    totalPotentialSavings: { $sum: '$potentialSavings' },
                    inefficientAppliances: {
                        $sum: {
                            $cond: [{ $lt: ['$efficiencyScore', 60] }, '$count', 0]
                        }
                    },
                    byCategory: {
                        $push: {
                            category: '$category',
                            efficiencyScore: '$efficiencyScore',
                            potentialSavings: '$potentialSavings',
                            dailyConsumption: '$dailyConsumption'
                        }
                    }
                }
            },
            {
                $project: {
                    _id: 0,
                    totalAppliances: 1,
                    averageEfficiency: { $round: ['$averageEfficiency', 2] },
                    totalPotentialSavings: { $round: ['$totalPotentialSavings', 2] },
                    inefficientAppliances: 1,
                    inefficiencyPercentage: {
                        $round: [
                            { $multiply: [{ $divide: ['$inefficientAppliances', '$totalAppliances'] }, 100] },
                            2
                        ]
                    },
                    byCategory: 1
                }
            }
        ]);
    }

    async updateAppliancesBulk(userId, appliances) {
        // First, deactivate existing appliances
        await this.updateMany(
            { userId, isActive: true },
            { isActive: false }
        );

        // Create new appliances
        const appliancesWithUserId = appliances.map(app => ({
            ...app,
            userId
        }));

        return this.bulkCreate(appliancesWithUserId);
    }

    async searchAppliances(userId, query, filters = {}) {
        const searchRegex = new RegExp(query, 'i');
        const searchFilter = {
            userId,
            isActive: true,
            $or: [
                { title: searchRegex },
                { category: searchRegex },
                { brand: searchRegex }
            ]
        };

        if (filters.category) {
            searchFilter.category = filters.category;
        }
        if (filters.usageLevel) {
            searchFilter.usageLevel = filters.usageLevel;
        }
        if (filters.minWattage) {
            searchFilter.wattage = { $gte: filters.minWattage };
        }
        if (filters.maxWattage) {
            searchFilter.wattage = { ...searchFilter.wattage, $lte: filters.maxWattage };
        }

        return this.findWithPagination(searchFilter, filters.pagination, {
            sort: { title: 1 }
        });
    }

    async getApplianceCategories(userId) {
        return this.distinct('category', { userId, isActive: true });
    }

    async getApplianceBrands(userId) {
        return this.distinct('brand', { userId, isActive: true, brand: { $ne: null } });
    }

    async getUsageStatistics(userId, period = 'daily') {
        const groupBy = period === 'daily' ? '$usageHoursPerDay' : '$usageLevel';
        
        return this.aggregate([
            { $match: { userId, isActive: true } },
            {
                $group: {
                    _id: groupBy,
                    count: { $sum: '$count' },
                    totalWattage: { $sum: { $multiply: ['$wattage', '$count'] } },
                    totalDailyConsumption: {
                        $sum: { $multiply: ['$wattage', '$usageHoursPerDay', '$count', 0.001] }
                    }
                }
            },
            {
                $project: {
                    [period === 'daily' ? 'usageHours' : 'usageLevel']: '$_id',
                    count: 1,
                    totalWattage: 1,
                    totalDailyConsumption: 1,
                    averageConsumption: {
                        $divide: ['$totalDailyConsumption', '$count']
                    }
                }
            },
            { $sort: { '_id': 1 } }
        ]);
    }

    async softDeleteAppliances(userId) {
        return this.updateMany(
            { userId, isActive: true },
            { isActive: false }
        );
    }

    async restoreAppliances(userId) {
        return this.updateMany(
            { userId, isActive: false },
            { isActive: true }
        );
    }
}

module.exports = ApplianceRepository;
