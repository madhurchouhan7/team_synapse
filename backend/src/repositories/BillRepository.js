// src/repositories/BillRepository.js
// Bill-specific repository with custom methods

const BaseRepository = require('./BaseRepository');
const Bill = require('../models/Bill.model');
const mongoose = require('mongoose');

class BillRepository extends BaseRepository {
    constructor() {
        super(Bill);
    }

    // ─── Bill-Specific Methods ─────────────────────────────────────────────────

    async getLatestByUser(userId) {
        return this.findOne(
            { userId, isActive: true },
            { sort: { periodEnd: -1 } }
        );
    }

    async getByDateRange(userId, startDate, endDate) {
        return this.find({
            userId,
            periodStart: { $gte: startDate },
            periodEnd: { $lte: endDate },
            isActive: true
        }).sort({ periodStart: -1 });
    }

    async getConsumptionStats(userId, months = 12) {
        const startDate = new Date();
        startDate.setMonth(startDate.getMonth() - months);

        return this.aggregate([
            {
                $match: {
                    userId: new mongoose.Types.ObjectId(userId),
                    periodStart: { $gte: startDate },
                    isActive: true
                }
            },
            {
                $group: {
                    _id: {
                        year: { $year: '$periodStart' },
                        month: { $month: '$periodStart' }
                    },
                    totalUnits: { $sum: '$units' },
                    totalAmount: { $sum: '$amount' },
                    averageDailyUnits: { $avg: '$averageDailyConsumption' },
                    billCount: { $sum: 1 },
                    averageBillAmount: { $avg: '$amount' },
                    maxUnits: { $max: '$units' },
                    minUnits: { $min: '$units' }
                }
            },
            {
                $addFields: {
                    monthName: {
                        $let: {
                            vars: {
                                monthsInYear: [
                                    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                                ]
                            },
                            in: { $arrayElemAt: ['$$monthsInYear', { $subtract: ['$_id.month', 1] }] }
                        }
                    }
                }
            },
            {
                $project: {
                    _id: 0,
                    year: '$_id.year',
                    month: '$_id.month',
                    monthName: 1,
                    totalUnits: 1,
                    totalAmount: 1,
                    averageDailyUnits: { $round: ['$averageDailyUnits', 2] },
                    billCount: 1,
                    averageBillAmount: { $round: ['$averageBillAmount', 2] },
                    maxUnits: 1,
                    minUnits: 1,
                    costPerUnit: {
                        $round: [{ $divide: ['$totalAmount', '$totalUnits'] }, 2]
                    }
                }
            },
            { $sort: { year: -1, month: -1 } }
        ]);
    }

    async getYearlyComparison(userId, years = 2) {
        const currentYear = new Date().getFullYear();
        const startYear = currentYear - years + 1;

        return this.aggregate([
            {
                $match: {
                    userId: new mongoose.Types.ObjectId(userId),
                    'periodStart.year': { $gte: startYear },
                    isActive: true
                }
            },
            {
                $group: {
                    _id: { $year: '$periodStart' },
                    totalUnits: { $sum: '$units' },
                    totalAmount: { $sum: '$amount' },
                    billCount: { $sum: 1 },
                    averageBillAmount: { $avg: '$amount' },
                    maxBillAmount: { $max: '$amount' },
                    minBillAmount: { $min: '$amount' }
                }
            },
            {
                $project: {
                    year: '$_id',
                    totalUnits: 1,
                    totalAmount: 1,
                    billCount: 1,
                    averageBillAmount: { $round: ['$averageBillAmount', 2] },
                    maxBillAmount: 1,
                    minBillAmount: 1,
                    averageUnitsPerBill: { $round: [{ $divide: ['$totalUnits', '$billCount'] }, 2] },
                    costPerUnit: { $round: [{ $divide: ['$totalAmount', '$totalUnits'] }, 2] }
                }
            },
            { $sort: { year: -1 } }
        ]);
    }

    async getOverdueBills(userId) {
        const today = new Date();

        return this.find({
            userId,
            dueDate: { $lt: today },
            status: { $ne: 'PAID' },
            isActive: true
        }).sort({ dueDate: 1 });
    }

    async getUpcomingBills(userId, days = 30) {
        const futureDate = new Date();
        futureDate.setDate(futureDate.getDate() + days);

        return this.find({
            userId,
            dueDate: { $lte: futureDate, $gte: new Date() },
            status: { $ne: 'PAID' },
            isActive: true
        }).sort({ dueDate: 1 });
    }

    async getBillsByStatus(userId) {
        return this.aggregate([
            { $match: { userId: new mongoose.Types.ObjectId(userId), isActive: true } },
            {
                $group: {
                    _id: '$status',
                    count: { $sum: 1 },
                    totalAmount: { $sum: '$amount' },
                    averageAmount: { $avg: '$amount' }
                }
            },
            {
                $project: {
                    status: '$_id',
                    count: 1,
                    totalAmount: 1,
                    averageAmount: { $round: ['$averageAmount', 2] }
                }
            }
        ]);
    }

    async getMonthlyTrend(userId, months = 12) {
        const startDate = new Date();
        startDate.setMonth(startDate.getMonth() - months);

        return this.aggregate([
            {
                $match: {
                    userId: new mongoose.Types.ObjectId(userId),
                    periodStart: { $gte: startDate },
                    isActive: true
                }
            },
            {
                $group: {
                    _id: {
                        year: { $year: '$periodStart' },
                        month: { $month: '$periodStart' }
                    },
                    totalUnits: { $sum: '$units' },
                    totalAmount: { $sum: '$amount' },
                    billCount: { $sum: 1 }
                }
            },
            {
                $addFields: {
                    monthName: {
                        $let: {
                            vars: {
                                monthsInYear: [
                                    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                                ]
                            },
                            in: { $arrayElemAt: ['$$monthsInYear', { $subtract: ['$_id.month', 1] }] }
                        }
                    },
                    yearMonth: { $concat: [{ $toString: '$_id.year' }, '-', { $toString: '$_id.month' }] }
                }
            },
            {
                $project: {
                    _id: 0,
                    yearMonth: 1,
                    monthName: 1,
                    year: '$_id.year',
                    month: '$_id.month',
                    totalUnits: 1,
                    totalAmount: 1,
                    billCount: 1,
                    averageUnitsPerBill: { $round: [{ $divide: ['$totalUnits', '$billCount'] }, 2] },
                    costPerUnit: { $round: [{ $divide: ['$totalAmount', '$totalUnits'] }, 2] }
                }
            },
            { $sort: { year: 1, month: 1 } }
        ]);
    }

    async getConsumptionAnomalies(userId) {
        // Find bills with unusual consumption patterns
        const stats = await this.aggregate([
            { $match: { userId: new mongoose.Types.ObjectId(userId), isActive: true } },
            {
                $group: {
                    _id: null,
                    avgUnits: { $avg: '$units' },
                    stdDevUnits: { $stdDevPop: '$units' },
                    minUnits: { $min: '$units' },
                    maxUnits: { $max: '$units' }
                }
            }
        ]);

        if (stats.length === 0) return [];

        const { avgUnits, stdDevUnits } = stats[0];
        const threshold = 2 * stdDevUnits; // 2 standard deviations

        return this.find({
            userId,
            isActive: true,
            $or: [
                { units: { $gt: avgUnits + threshold } },
                { units: { $lt: Math.max(0, avgUnits - threshold) } }
            ]
        }).sort({ periodStart: -1 });
    }

    async getBillsBySource(userId) {
        return this.aggregate([
            { $match: { userId: new mongoose.Types.ObjectId(userId), isActive: true } },
            {
                $group: {
                    _id: '$source',
                    count: { $sum: 1 },
                    totalAmount: { $sum: '$amount' },
                    totalUnits: { $sum: '$units' },
                    averageAmount: { $avg: '$amount' },
                    averageUnits: { $avg: '$units' }
                }
            },
            {
                $project: {
                    source: '$_id',
                    count: 1,
                    totalAmount: 1,
                    totalUnits: 1,
                    averageAmount: { $round: ['$averageAmount', 2] },
                    averageUnits: { $round: ['$averageUnits', 2] }
                }
            }
        ]);
    }

    async searchBills(userId, query, filters = {}) {
        const searchRegex = new RegExp(query, 'i');
        const searchFilter = {
            userId,
            isActive: true,
            $or: [
                { billNumber: searchRegex },
                { consumerNumber: searchRegex },
                { billerId: searchRegex }
            ]
        };

        if (filters.status) {
            searchFilter.status = filters.status;
        }
        if (filters.source) {
            searchFilter.source = filters.source;
        }
        if (filters.startDate) {
            searchFilter.periodStart = { $gte: new Date(filters.startDate) };
        }
        if (filters.endDate) {
            searchFilter.periodEnd = { ...searchFilter.periodEnd, $lte: new Date(filters.endDate) };
        }

        return this.findWithPagination(searchFilter, filters.pagination, {
            sort: { periodEnd: -1 }
        });
    }

    async markAsPaid(billId, paymentMethod = 'manual') {
        return this.updateById(billId, {
            status: 'PAID',
            paidAt: new Date(),
            paymentMethod
        });
    }

    async getPaymentSummary(userId) {
        return this.aggregate([
            { $match: { userId: new mongoose.Types.ObjectId(userId), isActive: true } },
            {
                $group: {
                    _id: '$status',
                    count: { $sum: 1 },
                    totalAmount: { $sum: '$amount' },
                    averageAmount: { $avg: '$amount' }
                }
            },
            {
                $group: {
                    _id: null,
                    statuses: {
                        $push: {
                            status: '$_id',
                            count: '$count',
                            totalAmount: '$totalAmount',
                            averageAmount: '$averageAmount'
                        }
                    },
                    totalBills: { $sum: '$count' },
                    totalValue: { $sum: '$totalAmount' },
                    paidAmount: {
                        $sum: {
                            $cond: [{ $eq: ['$_id', 'PAID'] }, '$totalAmount', 0]
                        }
                    },
                    unpaidAmount: {
                        $sum: {
                            $cond: [{ $ne: ['$_id', 'PAID'] }, '$totalAmount', 0]
                        }
                    }
                }
            },
            {
                $project: {
                    _id: 0,
                    statuses: 1,
                    totalBills: 1,
                    totalValue: 1,
                    paidAmount: 1,
                    unpaidAmount: 1,
                    paymentRate: {
                        $round: [{ $multiply: [{ $divide: ['$paidAmount', '$totalValue'] }, 100] }, 2]
                    }
                }
            }
        ]);
    }
}

module.exports = BillRepository;
