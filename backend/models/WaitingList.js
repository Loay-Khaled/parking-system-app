const mongoose = require('mongoose');

const waitingListSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  position: { type: Number, required: true },
  // 'waiting'  → in queue, no offer yet
  // 'offered'  → a spot has been offered, pending accept/decline
  // 'accepted' → user accepted and spot was booked
  // 'declined' → user declined, move to next in queue
  // 'expired'  → offer timed out (5 min window), move to next
  status: { type: String, enum: ['waiting', 'offered', 'accepted', 'declined', 'expired'], default: 'waiting' },
  offeredSpotId: { type: String, default: null },   // Which spot was offered
  offerExpiresAt: { type: Date, default: null },     // Offer expires after 5 minutes
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('WaitingList', waitingListSchema);
