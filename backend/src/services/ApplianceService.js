// src/services/ApplianceService.js
// Appliance service layer with business logic

const BaseService = require('./BaseService');
const ApplianceRepository = require('../repositories/ApplianceRepository');
const ApiError = require('../utils/ApiError');

class ApplianceService extends BaseService {
    constructor() {
        super(new ApplianceRepository());
    }

    // ─── Appliance Business Logic ───────────────────────────────────────────────

    async createAppliance(userId, applianceData) {
        // Validate business rules
        await this.validateApplianceData(applianceData);
        
        // Check for duplicate appliances
        const existingAppliance = await this.repository.findOne({
            userId,
            applianceId: applianceData.applianceId,
            isActive: true
        });
        
        if (existingAppliance) {
            throw new ApiError(409, 'Appliance with this ID already exists');
        }
        
        // Create appliance with user context
        const appliance = await this.repository.create({
            ...applianceData,
            userId
        });
        
        // Log activity
        await this.logActivity(userId, 'create_appliance', { applianceId: appliance._id });
        
        return appliance;
    }

    async updateAppliance(userId, applianceId, updateData) {
        // Validate ownership
        await this.validateOwnership(userId, applianceId);
        
        // Validate update data
        await this.validateApplianceData(updateData, true);
        
        // Update appliance
        const appliance = await this.repository.updateById(applianceId, updateData);
        
        // Log activity
        await this.logActivity(userId, 'update_appliance', { applianceId });
        
        return appliance;
    }

    async deleteAppliance(userId, applianceId) {
        // Validate ownership
        await this.validateOwnership(userId, applianceId);
        
        // Soft delete appliance
        const appliance = await this.softDelete(applianceId);
        
        // Log activity
        await this.logActivity(userId, 'delete_appliance', { applianceId });
        
        return appliance;
    }

    async getUserAppliances(userId, filters = {}) {
        const filter = { userId, isActive: true };
        
        // Apply filters
        if (filters.category) {
            filter.category = filters.category;
        }
        if (filters.usageLevel) {
            filter.usageLevel = filters.usageLevel;
        }
        
        const appliances = await this.repository.find(filter, {
            sort: { createdAt: -1 }
        });
        
        return appliances;
    }

    async getApplianceSummary(userId) {
        const summary = await this.repository.getTotalConsumption(userId);
        
        // Add additional business metrics
        const categories = await this.repository.getConsumptionByCategory(userId);
        const usageLevels = await this.repository.getConsumptionByUsageLevel(userId);
        const highConsumption = await this.repository.getHighConsumptionAppliances(userId, 5);
        
        return {
            ...summary,
            categories,
            usageLevels,
            highConsumptionAppliances: highConsumption,
            efficiencyReport: await this.getEfficiencyReport(userId)
        };
    }

    async bulkUpdateAppliances(userId, appliances) {
        // Validate all appliances
        for (const appliance of appliances) {
            await this.validateApplianceData(appliance);
        }
        
        // Bulk update with soft delete of existing
        const result = await this.repository.updateAppliancesBulk(userId, appliances);
        
        // Log activity
        await this.logActivity(userId, 'bulk_update_appliances', { count: appliances.length });
        
        return result;
    }

    async getEfficiencyReport(userId) {
        const report = await this.repository.getApplianceEfficiencyReport(userId);
        
        // Add business insights
        const insights = this.generateEfficiencyInsights(report);
        
        return {
            ...report,
            insights,
            recommendations: this.generateEfficiencyRecommendations(report)
        };
    }

    async searchAppliances(userId, query, filters = {}) {
        const searchFilter = await this.buildSearchFilter(query, ['title', 'category', 'brand']);
        searchFilter.userId = userId;
        searchFilter.isActive = true;
        
        // Apply additional filters
        if (filters.category) searchFilter.category = filters.category;
        if (filters.usageLevel) searchFilter.usageLevel = filters.usageLevel;
        if (filters.minWattage) searchFilter.wattage = { $gte: filters.minWattage };
        if (filters.maxWattage) searchFilter.wattage = { ...searchFilter.wattage, $lte: filters.maxWattage };
        
        return this.repository.findWithPagination(searchFilter, filters.pagination, {
            sort: { title: 1 }
        });
    }

    async getApplianceCategories(userId) {
        return this.repository.getApplianceCategories(userId);
    }

    async getApplianceBrands(userId) {
        return this.repository.getApplianceBrands(userId);
    }

    async getUsageStatistics(userId, period = 'daily') {
        return this.repository.getUsageStatistics(userId, period);
    }

    // ─── Business Logic Validation ─────────────────────────────────────────────

    async validateApplianceData(data, isUpdate = false) {
        const rules = {
            title: { required: !isUpdate, type: 'string', min: 1, max: 100 },
            category: { required: !isUpdate, type: 'string', enum: ['cooling', 'heating', 'lighting', 'entertainment', 'kitchen', 'laundry', 'cleaning', 'computing', 'charging', 'other'] },
            wattage: { type: 'number', min: 0, max: 10000 },
            usageHoursPerDay: { type: 'number', min: 0, max: 24 },
            usageLevel: { required: !isUpdate, type: 'string', enum: ['Low', 'Medium', 'High'] },
            count: { type: 'number', min: 1, max: 100 }
        };
        
        await this.validateDataIntegrity(data, rules);
        
        // Additional business validations
        if (data.wattage && data.wattage > 5000 && data.category !== 'heating' && data.category !== 'cooling') {
            throw new ApiError(400, 'Wattage seems unusually high for this appliance category');
        }
        
        if (data.usageHoursPerDay && data.count && data.usageHoursPerDay * data.count > 24) {
            throw new ApiError(400, 'Total usage hours exceed 24 hours per day');
        }
        
        return true;
    }

    // ─── Business Insights Generation ─────────────────────────────────────────────

    generateEfficiencyInsights(report) {
        const insights = [];
        
        if (report.inefficiencyPercentage > 50) {
            insights.push({
                type: 'warning',
                message: 'More than half of your appliances are inefficient',
                priority: 'high'
            });
        }
        
        if (report.totalPotentialSavings > 100) {
            insights.push({
                type: 'opportunity',
                message: `You could save ₹${report.totalPotentialSavings} per month with efficient appliances`,
                priority: 'medium'
            });
        }
        
        if (report.averageEfficiency < 60) {
            insights.push({
                type: 'recommendation',
                message: 'Consider upgrading to higher efficiency rated appliances',
                priority: 'low'
            });
        }
        
        return insights;
    }

    generateEfficiencyRecommendations(report) {
        const recommendations = [];
        
        // Find highest consuming categories
        if (report.byCategory && report.byCategory.length > 0) {
            const highestConsuming = report.byCategory[0];
            recommendations.push({
                category: highestConsuming.category,
                action: 'Focus on optimizing ' + highestConsuming.category + ' appliances',
                potentialSavings: Math.round(highestConsuming.totalDailyConsumption * 30 * 0.2), // 20% potential savings
                priority: 'high'
            });
        }
        
        // General recommendations based on efficiency
        if (report.averageEfficiency < 70) {
            recommendations.push({
                category: 'general',
                action: 'Upgrade to 5-star rated appliances for better efficiency',
                potentialSavings: Math.round(report.totalPotentialSavings * 0.5),
                priority: 'medium'
            });
        }
        
        return recommendations;
    }

    // ─── Analytics and Reporting ─────────────────────────────────────────────

    async getConsumptionTrends(userId, period = 'monthly', _months = 12) {
        // This would typically involve time-series analysis
        // For now, return basic consumption data
        const summary = await this.repository.getTotalConsumption(userId);
        
        return {
            period,
            data: {
                currentMonth: {
                    dailyConsumption: summary.totalDailyConsumption,
                    monthlyConsumption: summary.totalMonthlyConsumption
                },
                trend: 'stable', // Would be calculated from historical data
                forecast: summary.totalMonthlyConsumption // Simple forecast
            }
        };
    }

    async compareWithPeers(userId) {
        // Get user's consumption
        const userSummary = await this.repository.getTotalConsumption(userId);
        
        // This would typically compare with anonymized peer data
        // For now, return a basic comparison
        const peerAverage = userSummary.totalDailyConsumption * 0.8; // Assume peers are 20% more efficient
        
        return {
            userConsumption: userSummary.totalDailyConsumption,
            peerAverage,
            efficiency: userSummary.totalDailyConsumption <= peerAverage ? 'above_average' : 'below_average',
            savingsOpportunity: Math.max(0, userSummary.totalDailyConsumption - peerAverage)
        };
    }

    // ─── Maintenance and Lifecycle ─────────────────────────────────────────────

    async getMaintenanceSchedule(userId) {
        const appliances = await this.getUserAppliances(userId);
        
        const schedule = appliances.map(appliance => {
            const maintenanceInterval = this.getMaintenanceInterval(appliance.category);
            const lastMaintenance = appliance.lastMaintenance || appliance.createdAt;
            const nextMaintenance = new Date(lastMaintenance);
            nextMaintenance.setMonth(nextMaintenance.getMonth() + maintenanceInterval);
            
            return {
                applianceId: appliance._id,
                applianceName: appliance.title,
                category: appliance.category,
                lastMaintenance,
                nextMaintenance,
                isOverdue: new Date() > nextMaintenance,
                priority: this.getMaintenancePriority(appliance.category, appliance.usageLevel)
            };
        });
        
        return schedule.sort((a, b) => a.nextMaintenance - b.nextMaintenance);
    }

    getMaintenanceInterval(category) {
        const intervals = {
            'heating': 6,      // 6 months
            'cooling': 6,      // 6 months
            'kitchen': 3,      // 3 months
            'laundry': 6,      // 6 months
            'cleaning': 2,     // 2 months
            'entertainment': 12, // 1 year
            'lighting': 12,    // 1 year
            'computing': 6,    // 6 months
            'charging': 12,    // 1 year
            'other': 6         // 6 months
        };
        
        return intervals[category] || 6;
    }

    getMaintenancePriority(category, usageLevel) {
        if (usageLevel === 'High') return 'high';
        if (category === 'heating' || category === 'cooling') return 'high';
        if (usageLevel === 'Medium') return 'medium';
        return 'low';
    }
}

module.exports = ApplianceService;
