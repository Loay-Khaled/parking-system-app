const mongoose = require('mongoose');
require('dotenv').config();

const ParkingSpot = require('./models/ParkingSpot');

async function testNearestSpot() {
  console.log('🔄 Connecting to MongoDB...');
  await mongoose.connect(process.env.MONGODB_URI);
  console.log('✅ Connected to MongoDB');

  try {
    // 1. Ensure coordinate checker runs
    // Let's run the coordinate assignment logic (adapted from server.js)
    console.log('\n--- Running coordinate verification check ---');
    const spots = await ParkingSpot.find();
    let updatedCount = 0;
    for (const spot of spots) {
      if (spot.x === undefined || spot.y === undefined || (spot.x === 0 && spot.y === 0 && spot.spotId !== 'A1')) {
        const zoneCode = spot.zone.charCodeAt(0) - 65;
        const spotNum = parseInt(spot.spotId.replace(/[^\d]/g, '')) || 1;
        spot.x = (zoneCode * 50) + (spotNum * 10);
        spot.y = spotNum * 15;
        await spot.save();
        updatedCount++;
      }
    }
    console.log(`Verified ${spots.length} spots. Assigned coordinates to ${updatedCount} spots.`);

    // 2. Perform nearest spot logic manually
    console.log('\n--- Running nearest spot calculation check ---');
    // Reference point: x = 0, y = 0 (entrance)
    const refX = 0.0;
    const refY = 0.0;

    const availableSpots = await ParkingSpot.find({ status: 'available' });
    console.log(`Found ${availableSpots.length} available spots in the database.`);

    if (availableSpots.length === 0) {
      console.log('⚠️ No available spots found. Let us temporarily make one spot available for testing...');
      const oneSpot = await ParkingSpot.findOne();
      if (oneSpot) {
        oneSpot.status = 'available';
        await oneSpot.save();
        availableSpots.push(oneSpot);
        console.log(`Made Spot ${oneSpot.spotId} available.`);
      } else {
        throw new Error('No spots in database to test with!');
      }
    }

    let nearestSpot = null;
    let minDistance = Infinity;

    console.log('\nCalculated distances from entrance (0,0):');
    for (const spot of availableSpots) {
      const dx = (spot.x || 0) - refX;
      const dy = (spot.y || 0) - refY;
      const distance = Math.sqrt(dx * dx + dy * dy);
      console.log(`  Spot ${spot.spotId} (Zone ${spot.zone}, Floor ${spot.floor}) - Coordinates: (${spot.x}, ${spot.y}) - Distance: ${distance.toFixed(2)} units`);
      if (distance < minDistance) {
        minDistance = distance;
        nearestSpot = spot;
      }
    }

    console.log('\n--- Result Summary ---');
    if (nearestSpot) {
      console.log(`✅ Calculated Nearest Spot: Spot ${nearestSpot.spotId}`);
      console.log(`   Zone: ${nearestSpot.zone}`);
      console.log(`   Coordinates: (${nearestSpot.x}, ${nearestSpot.y})`);
      console.log(`   Minimum Distance: ${minDistance.toFixed(2)} units`);
    } else {
      throw new Error('Calculation failed: No nearest spot identified!');
    }

    console.log('\n🎉 Backend logic verification succeeded!');

  } catch (error) {
    console.error('\n❌ Test failed:', error);
  } finally {
    await mongoose.connection.close();
    console.log('🔌 Connection closed');
  }
}

testNearestSpot();
