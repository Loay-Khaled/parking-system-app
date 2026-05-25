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
  .then(() => {
    console.log('✅ Connected to MongoDB Atlas');
    seedParkingSpots(); // Seed initial parking spots
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
      for (let i = 1; i <= 6; i++) {
        spots.push({
          spotId: `${zone}${i}`,
          zone,
          status: Math.random() > 0.6 ? 'occupied' : 'available',
          floor: zone === 'A' ? 1 : zone === 'B' ? 2 : 3,
        });
      }
    });
    await ParkingSpot.insertMany(spots);
    console.log('✅ Parking spots seeded');
  }
}

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
