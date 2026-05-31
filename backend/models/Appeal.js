const mongoose = require('mongoose');

const appealSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  bookingId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Booking',
    required: true,
  },
  transactionId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Transaction',
    required: true,
  },
  penaltyAmount: {
    type: Number,
    required: true,
  },
  reason: {
    type: String,
    required: true,
    maxlength: 500,
  },
  status: {
    type: String,
    enum: ['pending', 'approved', 'rejected'],
    default: 'pending',
  },
  adminNote: {
    type: String,
    default: '',
  },
  resolvedAt: {
    type: Date,
  },
  resolvedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  },
}, {
  timestamps: true,
});

module.exports = mongoose.model('Appeal', appealSchema);
