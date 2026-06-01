const mongoose = require('mongoose');
require('dotenv').config();
const User = require('../models/User');
const Vehicle = require('../models/Vehicle');

async function syncVehicles() {
  console.log('🔄 Connecting to MongoDB...');
  await mongoose.connect(process.env.MONGODB_URI);
  console.log('✅ Connected to MongoDB');

  try {
    const users = await User.find({
      carPlate: { $exists: true, $ne: null, $ne: '' }
    });

    let syncedCount = 0;

    for (const user of users) {
      const exists = await Vehicle.findOne({ userId: user._id });
      if (!exists) {
        const plateExists = await Vehicle.findOne({ licensePlate: user.carPlate.toUpperCase() });
        if (!plateExists) {
          await Vehicle.create({
            userId: user._id,
            licensePlate: user.carPlate.toUpperCase(),
            brand: 'Default',
            model: 'Default',
            color: 'White',
          });
          syncedCount++;
        }
      }
    }

    console.log(`Synced vehicles for ${syncedCount} existing users.`);
  } catch (error) {
    console.error('Migration failed:', error);
  } finally {
    await mongoose.connection.close();
    console.log('🔌 Connection closed');
  }
}

syncVehicles();
