// scripts/migrateUserData.js
// Migration script to move embedded data from User model to separate collections

const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const User = require('../src/models/User.model');
const Address = require('../src/models/Address.model');
const Appliance = require('../src/models/Appliance.model');
const Bill = require('../src/models/Bill.model');
const Plan = require('../src/models/Plan.model');

const connectDB = async () => {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('✅ Connected to MongoDB');
    } catch (error) {
        console.error('❌ MongoDB connection failed:', error);
        process.exit(1);
    }
};

const migrateAddresses = async () => {
    console.log('🔄 Migrating addresses...');
    
    const usersWithAddresses = await User.find({
        'address.state': { $exists: true, $ne: null }
    });
    
    let migratedCount = 0;
    
    for (const user of usersWithAddresses) {
        const addressData = {
            userId: user._id,
            state: user.address.state,
            city: user.address.city,
            discom: user.address.discom,
            lat: user.address.lat,
            lng: user.address.lng,
            isPrimary: true,
        };
        
        try {
            await Address.create(addressData);
            migratedCount++;
            console.log(`✅ Migrated address for user: ${user.email}`);
        } catch (error) {
            if (error.code === 11000) {
                console.log(`⚠️  Address already exists for user: ${user.email}`);
            } else {
                console.error(`❌ Error migrating address for ${user.email}:`, error.message);
            }
        }
    }
    
    console.log(`✅ Addresses migration completed. Migrated: ${migratedCount}`);
    return migratedCount;
};

const migrateAppliances = async () => {
    console.log('🔄 Migrating appliances...');
    
    const usersWithAppliances = await User.find({
        appliances: { $exists: true, $ne: [] }
    });
    
    let migratedCount = 0;
    
    for (const user of usersWithAppliances) {
        for (const appliance of user.appliances) {
            const applianceData = {
                userId: user._id,
                applianceId: appliance.applianceId,
                title: appliance.title,
                category: appliance.category,
                usageHours: appliance.usageHours || 0,
                usageLevel: appliance.usageLevel,
                count: appliance.count || 1,
                selectedDropdowns: appliance.selectedDropdowns || {},
                svgPath: appliance.svgPath,
            };
            
            try {
                await Appliance.create(applianceData);
                migratedCount++;
            } catch (error) {
                if (error.code === 11000) {
                    console.log(`⚠️  Appliance already exists: ${appliance.title}`);
                } else {
                    console.error(`❌ Error migrating appliance ${appliance.title}:`, error.message);
                }
            }
        }
        
        console.log(`✅ Migrated ${user.appliances.length} appliances for user: ${user.email}`);
    }
    
    console.log(`✅ Appliances migration completed. Total migrated: ${migratedCount}`);
    return migratedCount;
};

const migrateBills = async () => {
    console.log('🔄 Migrating bills...');
    
    const usersWithBills = await User.find({
        bills: { $exists: true, $ne: [] }
    });
    
    let migratedCount = 0;
    
    for (const user of usersWithBills) {
        for (const bill of user.bills) {
            const billData = {
                userId: user._id,
                billNumber: bill.billNumber,
                consumerNumber: bill.consumerNumber,
                billerId: bill.billerId,
                source: bill.source || 'manual',
                status: bill.status || 'UNPAID',
                amount: bill.amount || 0,
                grossAmount: bill.grossAmount,
                subsidy: bill.subsidy || 0,
                units: bill.units || 0,
                periodStart: bill.periodStart,
                periodEnd: bill.periodEnd,
                dueDate: bill.dueDate,
                rawText: bill.rawText,
                imageBase64: bill.imageBase64,
                createdAt: bill.createdAt || new Date(),
            };
            
            try {
                await Bill.create(billData);
                migratedCount++;
            } catch (error) {
                if (error.code === 11000) {
                    console.log(`⚠️  Bill already exists: ${bill.billNumber}`);
                } else {
                    console.error(`❌ Error migrating bill ${bill.billNumber}:`, error.message);
                }
            }
        }
        
        console.log(`✅ Migrated ${user.bills.length} bills for user: ${user.email}`);
    }
    
    console.log(`✅ Bills migration completed. Total migrated: ${migratedCount}`);
    return migratedCount;
};

const migratePlans = async () => {
    console.log('🔄 Migrating plans...');
    
    const usersWithPlans = await User.find({
        activePlan: { $exists: true, $ne: null }
    });
    
    let migratedCount = 0;
    
    for (const user of usersWithPlans) {
        const planData = {
            userId: user._id,
            planType: 'efficiency',
            title: 'Active Efficiency Plan',
            status: 'active',
            summary: user.activePlan.summary || 'Efficiency plan',
            estimatedCurrentMonthlyCost: user.activePlan.estimatedCurrentMonthlyCost || 0,
            estimatedSavingsIfFollowed: user.activePlan.estimatedSavingsIfFollowed || {
                units: 0,
                rupees: 0,
                percentage: 0
            },
            efficiencyScore: user.activePlan.efficiencyScore || 0,
            keyActions: user.activePlan.keyActions || [],
            slabAlert: user.activePlan.slabAlert || {
                isInDangerZone: false,
                currentSlab: ''
            },
            quickWins: user.activePlan.quickWins || [],
            monthlyTip: user.activePlan.monthlyTip || '',
            generationContext: {
                userGoal: user.planPreferences?.mainGoals?.[0],
                focusArea: user.planPreferences?.focusArea,
            },
        };
        
        try {
            await Plan.create(planData);
            migratedCount++;
            console.log(`✅ Migrated plan for user: ${user.email}`);
        } catch (error) {
            if (error.code === 11000) {
                console.log(`⚠️  Plan already exists for user: ${user.email}`);
            } else {
                console.error(`❌ Error migrating plan for ${user.email}:`, error.message);
            }
        }
    }
    
    console.log(`✅ Plans migration completed. Migrated: ${migratedCount}`);
    return migratedCount;
};

const cleanupUserData = async () => {
    console.log('🧹 Cleaning up user documents...');
    
    const result = await User.updateMany(
        {},
        {
            $unset: {
                address: 1,
                appliances: 1,
                bills: 1,
                activePlan: 1,
                previousPlans: 1
            }
        }
    );
    
    console.log(`✅ Cleaned up ${result.modifiedCount} user documents`);
    return result.modifiedCount;
};

const runMigration = async () => {
    console.log('🚀 Starting data migration...');
    
    try {
        await connectDB();
        
        // Run migrations
        const addressCount = await migrateAddresses();
        const applianceCount = await migrateAppliances();
        const billCount = await migrateBills();
        const planCount = await migratePlans();
        
        // Ask for confirmation before cleanup
        console.log('\n📊 Migration Summary:');
        console.log(`   Addresses: ${addressCount}`);
        console.log(`   Appliances: ${applianceCount}`);
        console.log(`   Bills: ${billCount}`);
        console.log(`   Plans: ${planCount}`);
        
        console.log('\n⚠️  Ready to clean up user documents (remove embedded data).');
        console.log('   This action is irreversible!');
        
        // In production, you might want to add a confirmation prompt here
        const shouldCleanup = process.env.AUTO_CLEANUP === 'true';
        
        if (shouldCleanup) {
            await cleanupUserData();
            console.log('✅ Migration completed successfully!');
        } else {
            console.log('ℹ️  Migration data created. Run with AUTO_CLEANUP=true to clean up user documents.');
        }
        
    } catch (error) {
        console.error('❌ Migration failed:', error);
    } finally {
        await mongoose.disconnect();
        console.log('🔌 Disconnected from MongoDB');
    }
};

// Run migration if this file is executed directly
if (require.main === module) {
    runMigration();
}

module.exports = {
    migrateAddresses,
    migrateAppliances,
    migrateBills,
    migratePlans,
    cleanupUserData,
    runMigration,
};
