const mongoose = require('mongoose');

const parkingSpotSchema = new mongoose.Schema({
  spotId: { type: String, required: true, unique: true },
  zone: { type: String, required: true, enum: ['A', 'B', 'C'] },
  status: {
    type: String,
    enum: ['available', 'occupied', 'reserved'],
    default: 'available',
  },
  floor: { type: Number, default: 1 },
  currentBookingId: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', default: null },
  availableAt: { type: Date, default: null },
  updatedAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('ParkingSpot', parkingSpotSchema);
