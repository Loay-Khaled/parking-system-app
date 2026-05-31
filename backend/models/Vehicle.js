const mongoose = require('mongoose');

const vehicleSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  licensePlate: {
    type: String,
    required: true,
    unique: true,
  },
  brand: {
    type: String,
    required: true,
  },
  model: {
    type: String,
    required: true,
  },
  color: {
    type: String,
    required: true,
  },
});

module.exports = mongoose.model('Vehicle', vehicleSchema);
