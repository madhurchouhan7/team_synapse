require('dotenv').config();
const mongoose = require('mongoose');
const SmartPlug = require('./src/models/SmartPlug.model');

async function fix() {
  await mongoose.connect(process.env.MONGODB_URI);
  await SmartPlug.updateMany({}, { $set: { 'lastReading.isAnomaly': false, 'lastReading.wattage': 0 } });
  console.log("DB Anomalies Cleared!");
  process.exit(0);
}
fix();
