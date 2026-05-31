const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// MongoDB Connection
mongoose.connect(process.env.MONGODB_URI)
  .then(async () => {
    console.log('✅ Connected to MongoDB Atlas');
    await seedParkingSpots(); // Seed initial parking spots
    await ensureSpotCoordinates(); // Ensure all spots have coordinates
  })
  .catch(err => console.error('❌ MongoDB connection error:', err));

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/spots', require('./routes/spots'));
app.use('/api/bookings', require('./routes/bookings'));
app.use('/api/notifications', require('./routes/notifications'));
app.use('/api/waitinglist', require('./routes/waitinglist'));
app.use('/api/profile', require('./routes/profile'));
app.use('/api/admin', require('./routes/admin'));
app.use('/api/payments', require('./routes/payments'));
app.use('/api/vehicles', require('./routes/vehicles'));
app.use('/api/appeals', require('./routes/appeals'));
app.use('/api/recommendations', require('./routes/recommendations'));
app.use('/api/analytics', require('./routes/analytics'));
app.use('/api/transactions', require('./routes/transactions'));
app.use('/api/accessibility', require('./routes/accessibility'));

// Scheduled background cron jobs
const cron = require('node-cron');
const Booking = require('./models/Booking');
const ParkingSpot = require('./models/ParkingSpot');
const { triggerQueueForSpot } = require('./services/queueService');

// 1. Expiry Alert Monitor (every 1 minute)
cron.schedule('* * * * *', async () => {
  try {
    const now = new Date();
    const sixteenMinutesLater = new Date(now.getTime() + 16 * 60 * 1000);

    const bookingsToRemind = await Booking.find({
      status: 'active',
      reminderSent: false,
      endTime: { $gte: now, $lte: sixteenMinutesLater }
    });

    for (const booking of bookingsToRemind) {
      booking.reminderSent = true;
      await booking.save();
      console.log(`⏰ Reminder flag set for Booking ${booking._id}`);
    }
  } catch (err) {
    console.error('❌ Expiry Alert Cron Error:', err.message);
  }
});

// 2. No-Show Canceller (every 5 minutes)
cron.schedule('*/5 * * * *', async () => {
  try {
    const now = new Date();
    const fifteenMinutesAgo = new Date(now.getTime() - 15 * 60 * 1000);

    // Active, not checked in, and startTime is older than 15 minutes ago
    const expiredBookings = await Booking.find({
      status: 'active',
      isCheckedIn: false,
      startTime: { $lt: fifteenMinutesAgo }
    });

    const User = require('./models/User');
    const Transaction = require('./models/Transaction');

    for (const booking of expiredBookings) {
      booking.status = 'cancelled';
      booking.noShowCancelled = true;
      await booking.save();

      await ParkingSpot.findOneAndUpdate(
        { spotId: booking.spotId },
        { status: 'available', currentBookingId: null, availableAt: null }
      );

      // Create audit transaction for zero cost
      await Transaction.create({
        userId: booking.userId,
        type: 'payment',
        amount: 0,
        description: `Booking ${booking._id} auto-cancelled (no-show). Spot ${booking.spotId} freed at ${new Date().toISOString()}.`
      });

      // Refund the booking cost to the user's wallet
      const user = await User.findById(booking.userId);
      if (user && booking.cost > 0) {
        user.walletBalance += booking.cost;
        await user.save();
        await Transaction.create({
          userId: booking.userId,
          type: 'recharge',
          amount: booking.cost,
          description: `Refund for no-show cancelled booking ${booking._id}.`
        });
      }

      console.log(`🚫 Booking ${booking._id} cancelled due to no-show.`);
      
      // Trigger waiting list queue for the freed spot
      await triggerQueueForSpot(booking.spotId);
    }
  } catch (err) {
    console.error('❌ No-Show Canceller Cron Error:', err.message);
  }
});

// Health check
app.get('/', (req, res) => {
  res.json({ message: 'AAST Smart Parking API is running 🚀', version: '1.0.0' });
});

// Seed parking spots if empty
async function seedParkingSpots() {
  const ParkingSpot = require('./models/ParkingSpot');
  const count = await ParkingSpot.countDocuments();
  if (count === 0) {
    const spots = [];
    ['A', 'B', 'C'].forEach(zone => {
      const zoneCode = zone.charCodeAt(0) - 65; // A=0, B=1, C=2
      for (let i = 1; i <= 6; i++) {
        const id = `${zone}${i}`;
        const isAcc = id === 'A1' || id === 'B1';
        spots.push({
          spotId: id,
          zone,
          status: Math.random() > 0.6 ? 'occupied' : 'available',
          floor: zone === 'A' ? 1 : zone === 'B' ? 2 : 3,
          x: (zoneCode * 50) + (i * 10),
          y: i * 15,
          isAccessibility: isAcc,
          accessibilityLabel: isAcc ? 'Wheelchair Access' : '',
        });
      }
    });
    await ParkingSpot.insertMany(spots);
    console.log('✅ Parking spots seeded');
  } else {
    // Self-healing for existing seeded databases
    await ParkingSpot.updateMany(
      { spotId: { $in: ['A1', 'B1'] } },
      { $set: { isAccessibility: true, accessibilityLabel: 'Wheelchair Access' } }
    );
  }
}

// Self-healing function to assign coordinates to pre-existing spots
async function ensureSpotCoordinates() {
  const ParkingSpot = require('./models/ParkingSpot');
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
  if (updatedCount > 0) {
    console.log(`✅ Assigned coordinates to ${updatedCount} existing parking spots`);
  }
}

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
