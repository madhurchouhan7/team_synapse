// src/services/UserService.js
// User service layer with business logic

const BaseService = require('./BaseService');
const UserRepository = require('../repositories/UserRepository');
const ApiError = require('../utils/ApiError');

class UserService extends BaseService {
    constructor() {
        super(new UserRepository());
    }

    // ─── User Profile Management ─────────────────────────────────────────────────

    async getUserProfile(userId, { includeActivePlan = false } = {}) {
        // Exclude large blob fields at the DB query level to avoid fetching them at all.
        // - bills: contains imageBase64 strings (~3MB per document)
        // - activePlan: large AI-generated JSON (~400KB), served via /users/me/active-plan
        // - deviceTokens: internal, never returned to clients
        const selectProjection = includeActivePlan
            ? '-deviceTokens -__v -bills'
            : '-deviceTokens -__v -bills -activePlan';

        const user = await this.repository.findById(userId, { select: selectProjection });
        
        if (!user) {
            throw new ApiError(404, 'User not found');
        }
        
        return user.toJSON();
    }

    // Returns activePlan only — called by GET /users/me/active-plan
    async getActivePlan(userId) {
        const user = await this.repository.findById(userId, { select: 'activePlan' });
        if (!user) throw new ApiError(404, 'User not found');
        return user.activePlan || null;
    }

    async updateProfile(userId, updateData) {
        const allowedFields = ['name', 'monthlyBudget', 'currency', 'avatarUrl', 'address', 'onboardingCompleted'];
        const filteredData = {};
        
        for (const field of allowedFields) {
            if (updateData[field] !== undefined) {
                filteredData[field] = updateData[field];
            }
        }
        
        if (Object.keys(filteredData).length === 0) {
            throw new ApiError(400, 'No valid fields to update');
        }
        
        const user = await this.repository.updateById(userId, filteredData);
        
        // Log activity
        await this.logActivity(userId, 'update_profile', filteredData);
        
        return this.transformDocument(user, {
            excludeFields: ['deviceTokens', '__v']
        });
    }

    async updateHousehold(userId, householdData) {
        const user = await this.repository.findById(userId);
        
        if (!user) {
            throw new ApiError(404, 'User not found');
        }
        
        // Validate household data
        await this.validateHouseholdData(householdData);
        
        const updatedUser = await this.repository.updateById(userId, {
            household: { ...user.household, ...householdData }
        });
        
        // Log activity
        await this.logActivity(userId, 'update_household', householdData);
        
        return updatedUser;
    }

    async updatePreferences(userId, preferences) {
        const allowedFields = ['mainGoals', 'focusArea'];
        const filteredData = {};
        
        for (const field of allowedFields) {
            if (preferences[field] !== undefined) {
                filteredData[field] = preferences[field];
            }
        }
        
        const user = await this.repository.findById(userId);
        
        if (!user) {
            throw new ApiError(404, 'User not found');
        }
        
        const updatedUser = await this.repository.updateById(userId, {
            planPreferences: { ...user.planPreferences, ...filteredData }
        });
        
        // Log activity
        await this.logActivity(userId, 'update_preferences', filteredData);
        
        return updatedUser;
    }

    // ─── Device Token Management ─────────────────────────────────────────────────

    async addDeviceToken(userId, token, platform = 'unknown') {
        const user = await this.repository.addDeviceToken(userId, token, platform);
        
        // Log activity
        await this.logActivity(userId, 'add_device_token', { platform });
        
        return user;
    }

    async removeDeviceToken(userId, token) {
        const user = await this.repository.removeDeviceToken(userId, token);
        
        // Log activity
        await this.logActivity(userId, 'remove_device_token');
        
        return user;
    }

    // ─── Onboarding ─────────────────────────────────────────────────────────

    async completeOnboarding(userId) {
        const user = await this.repository.updateById(userId, {
            onboardingCompleted: true
        });
        
        // Log activity
        await this.logActivity(userId, 'complete_onboarding');
        
        return user;
    }

    // ─── Streak / Check-in Management ───────────────────────────────────────────

    async recordCheckIn(userId) {
        const user = await this.repository.findById(userId);
        if (!user) throw new ApiError(404, 'User not found');

        const nowUtc = new Date();
        const todayUtc = new Date(Date.UTC(
            nowUtc.getUTCFullYear(), nowUtc.getUTCMonth(), nowUtc.getUTCDate()
        ));

        let streak = user.streak || 0;
        let longestStreak = user.longestStreak || 0;
        const lastCheckIn = user.lastCheckIn;
        let alreadyCheckedIn;
        let message;

        if (lastCheckIn) {
            const lastDay = new Date(Date.UTC(
                lastCheckIn.getUTCFullYear(),
                lastCheckIn.getUTCMonth(),
                lastCheckIn.getUTCDate()
            ));
            const diffDays = Math.round((todayUtc - lastDay) / (1000 * 60 * 60 * 24));

            if (diffDays === 0) {
                // Already checked in today
                alreadyCheckedIn = true;
                message = 'Already checked in today.';
                return { streak, lastCheckIn, longestStreak, alreadyCheckedIn, message };
            } else if (diffDays === 1) {
                streak += 1;
                message = `Streak extended to ${streak} days!`;
            } else {
                streak = 1;
                message = 'Streak restarted!';
            }
        } else {
            streak = 1;
            message = 'First check-in! Streak started.';
        }

        if (streak > longestStreak) longestStreak = streak;

        await this.repository.updateById(userId, {
            streak,
            lastCheckIn: nowUtc,
            longestStreak,
        });

        await this.logActivity(userId, 'check_in', { streak });

        return { streak, lastCheckIn: nowUtc, longestStreak, alreadyCheckedIn: false, message };
    }

    async getStreakData(userId) {
        const user = await this.repository.findById(userId);
        if (!user) throw new ApiError(404, 'User not found');

        return {
            streak: user.streak || 0,
            lastCheckIn: user.lastCheckIn || null,
            longestStreak: user.longestStreak || 0,
        };
    }

    async updateStreak(userId, streak, lastCheckIn) {
        const user = await this.repository.findById(userId);
        if (!user) throw new ApiError(404, 'User not found');

        const longestStreak = Math.max(user.longestStreak || 0, streak);
        await this.repository.updateById(userId, { streak, lastCheckIn, longestStreak });
    }

    // ─── Active Plan Management ───────────────────────────────────────────────

    async updateActivePlan(userId, planData) {
        await this.repository.updateById(userId, { activePlan: planData });
        await this.logActivity(userId, planData ? 'activate_plan' : 'delete_plan');
    }

    // ─── Daily Heatmap Management ────────────────────────────────────────────────

    /**
     * Records today's intensity level into the dailyHeatmap field.
     * Uses MongoDB dot-notation $set so we only write ONE key, not the entire map.
     *
     * Intensity mapping:
     *   0 = no actions completed
     *   1 = 1–33% completed
     *   2 = 34–66% completed
     *   3 = 67–100% completed
     */
    async recordHeatmapEntry(userId, completedCount, totalCount) {
        let intensity = 0;
        if (totalCount > 0) {
            const ratio = completedCount / totalCount;
            if (ratio <= 0) intensity = 0;
            else if (ratio <= 0.33) intensity = 1;
            else if (ratio <= 0.66) intensity = 2;
            else intensity = 3;
        }

        const now = new Date();
        // Use UTC date string as key: "YYYY-MM-DD"
        const dateKey = now.toISOString().slice(0, 10);

        // $set with dot notation to write only today's key — avoids replacing the full map
        const User = require('../models/User.model');
        await User.findByIdAndUpdate(
            userId,
            { $set: { [`dailyHeatmap.${dateKey}`]: intensity } },
            { new: false }
        );

        await this.logActivity(userId, 'update_heatmap', { dateKey, intensity, completedCount, totalCount });

        return { dateKey, intensity };
    }

    /**
     * Returns a filtered subset of dailyHeatmap for a specific year-month.
     * The result is a Map<"YYYY-MM-DD", 0|1|2|3> (plain object).
     */
    async getMonthlyHeatmap(userId, year, month) {
        const User = require('../models/User.model');
        const user = await User.findById(userId).select('dailyHeatmap').lean();

        if (!user || !user.dailyHeatmap) return {};

        const prefix = `${year}-${String(month).padStart(2, '0')}-`;
        const filtered = {};

        for (const [dateKey, intensity] of Object.entries(user.dailyHeatmap)) {
            if (dateKey.startsWith(prefix)) {
                filtered[dateKey] = intensity;
            }
        }

        return filtered;
    }



    async getUserStats(userId) {
        // Get user stats from repository
        const user = await this.repository.findById(userId);
        
        if (!user) {
            throw new ApiError(404, 'User not found');
        }
        
        // This would typically aggregate data from other collections
        // For now, return basic user stats
        return {
            profile: {
                name: user.name,
                email: user.email,
                onboardingCompleted: user.onboardingCompleted,
                subscriptionTier: user.subscriptionTier,
                createdAt: user.createdAt
            },
            household: user.household,
            preferences: user.planPreferences,
            // Add more stats as needed
        };
    }

    // ─── Subscription Management ─────────────────────────────────────────────────

    async updateSubscription(userId, tier, expiresAt) {
        const validTiers = ['free', 'premium', 'enterprise'];
        
        if (!validTiers.includes(tier)) {
            throw new ApiError(400, 'Invalid subscription tier');
        }
        
        const user = await this.repository.updateSubscription(userId, tier, expiresAt);
        
        // Log activity
        await this.logActivity(userId, 'update_subscription', { tier, expiresAt });
        
        return user;
    }

    // ─── Account Management ─────────────────────────────────────────────────

    async deleteAccount(userId) {
        // Soft delete user account
        const user = await this.repository.softDeleteUser(userId);
        
        // Log activity
        await this.logActivity(userId, 'delete_account');
        
        return user;
    }

    async exportUserData(userId) {
        // Get all user data for export
        const user = await this.repository.findById(userId);
        
        if (!user) {
            throw new ApiError(404, 'User not found');
        }
        
        // This would typically collect data from all related collections
        return {
            user: this.transformDocument(user),
            exportedAt: new Date(),
            format: 'json'
        };
    }

    // ─── Search and Discovery ─────────────────────────────────────────────────

    async searchUsers(query, options = {}) {
        return this.repository.searchUsers(query, options);
    }

    async getUserById(userId, options = {}) {
        const user = await this.repository.findById(userId, options);
        
        if (!user) {
            throw new ApiError(404, 'User not found');
        }
        
        return user;
    }

    // ─── Activity Tracking ─────────────────────────────────────────────────

    async getUserActivity(userId, options = {}) {
        // This would typically fetch from an activity log collection
        // For now, return a placeholder
        return {
            activities: [],
            pagination: options.pagination || { page: 1, limit: 20 }
        };
    }

    // ─── Email Verification ─────────────────────────────────────────────────

    async verifyEmail(_token) {
        // This would typically verify a token and update user status
        // For now, return a placeholder
        return {
            verified: true,
            message: 'Email verified successfully'
        };
    }

    // ─── Password Management ─────────────────────────────────────────────────

    async forgotPassword(_email) {
        // This would typically send a password reset email
        // For now, return a placeholder
        return {
            message: 'Password reset email sent'
        };
    }

    async resetPassword(_token, _newPassword) {
        // This would typically verify token and update password
        // For now, return a placeholder
        return {
            message: 'Password reset successfully'
        };
    }

    // ─── Admin Functions ─────────────────────────────────────────────────

    async getAdminStats() {
        return this.repository.getUserStats();
    }

    async getAllUsers(options = {}) {
        const filter = { isActive: true };
        
        if (options.filters) {
            if (options.filters.tier) {
                filter.subscriptionTier = options.filters.tier;
            }
            if (options.filters.status) {
                filter.isVerified = options.filters.status === 'verified';
            }
            if (options.filters.search) {
                const searchFilter = await this.buildSearchFilter(options.filters.search, ['name', 'email']);
                Object.assign(filter, searchFilter);
            }
        }
        
        return this.repository.findWithPagination(filter, options.pagination, {
            sort: { createdAt: -1 },
            select: 'name email subscriptionTier createdAt lastLoginAt isVerified'
        });
    }

    async updateUserStatus(userId, status) {
        const updates = {};
        
        if (status === 'active') {
            updates.isActive = true;
        } else if (status === 'inactive') {
            updates.isActive = false;
        } else if (status === 'verified') {
            updates.isVerified = true;
        }
        
        const user = await this.repository.updateById(userId, updates);
        
        // Log activity
        await this.logActivity(userId, 'admin_update_status', { status });
        
        return user;
    }

    async impersonateUser(userId) {
        const user = await this.repository.findById(userId);
        
        if (!user) {
            throw new ApiError(404, 'User not found');
        }
        
        if (!user.isActive) {
            throw new ApiError(403, 'User account is inactive');
        }
        
        // Log activity
        await this.logActivity(userId, 'admin_impersonate');
        
        return this.transformDocument(user, {
            excludeFields: ['deviceTokens', '__v']
        });
    }

    // ─── Business Logic Validation ─────────────────────────────────────────────

    async validateHouseholdData(data) {
        const rules = {
            peopleCount: { type: 'number', min: 1, max: 20 },
            familyType: { type: 'string', enum: ['Just Me', 'Small', 'Large', 'Joint'] },
            houseType: { type: 'string', enum: ['Apartment', 'Bungalow', 'Independent'] }
        };
        
        await this.validateDataIntegrity(data, rules);
        return true;
    }

    // ─── Business Intelligence ─────────────────────────────────────────────────

    async getUserInsights(userId) {
        const user = await this.repository.findById(userId);
        
        if (!user) {
            throw new ApiError(404, 'User not found');
        }
        
        // Generate insights based on user data
        const insights = [];
        
        if (!user.onboardingCompleted) {
            insights.push({
                type: 'onboarding',
                message: 'Complete onboarding to get personalized recommendations',
                priority: 'high'
            });
        }
        
        if (user.subscriptionTier === 'free') {
            insights.push({
                type: 'upgrade',
                message: 'Upgrade to premium for advanced features',
                priority: 'medium'
            });
        }
        
        if (!user.monthlyBudget || user.monthlyBudget === 0) {
            insights.push({
                type: 'budget',
                message: 'Set a monthly budget to track expenses',
                priority: 'medium'
            });
        }
        
        return insights;
    }

    async getSubscriptionRecommendations(userId) {
        const user = await this.repository.findById(userId);
        
        if (!user) {
            throw new ApiError(404, 'User not found');
        }
        
        // Analyze usage patterns to recommend subscription tier
        const recommendations = [];
        
        if (user.subscriptionTier === 'free') {
            recommendations.push({
                tier: 'premium',
                reasons: [
                    'Unlimited bill uploads',
                    'Advanced analytics',
                    'Priority support'
                ],
                benefits: 'Get 50% more features for just ₹99/month'
            });
        }
        
        if (user.subscriptionTier === 'premium') {
            recommendations.push({
                tier: 'enterprise',
                reasons: [
                    'API access',
                    'Custom reports',
                    'Dedicated support'
                ],
                benefits: 'Perfect for power users and businesses'
            });
        }
        
        return recommendations;
    }
}

module.exports = UserService;
