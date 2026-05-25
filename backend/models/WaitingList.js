const mongoose = require('mongoose');

const waitingListSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  position: { type: Number, required: true },
  status: { type: String, enum: ['waiting', 'notified', 'expired'], default: 'waiting' },
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('WaitingList', waitingListSchema);
