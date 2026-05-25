const router = require('express').Router();
const auth = require('../middleware/auth');
const WaitingList = require('../models/WaitingList');
const ParkingSpot = require('../models/ParkingSpot');
const { acceptOffer, declineOffer } = require('../services/queueService');

// Get my queue status (returns inQueue, position, offer details if any)
router.get('/my', auth, async (req, res) => {
  try {
    const entry = await WaitingList.findOne({
      userId: req.user._id,
      status: { $in: ['waiting', 'offered'] }
    });
    const total = await WaitingList.countDocuments({ status: { $in: ['waiting', 'offered'] } });

    if (!entry) {
      return res.json({ inQueue: false, position: null, totalWaiting: total });
    }

    res.json({
      inQueue: true,
      entryId: entry._id,
      position: entry.position,
      totalWaiting: total,
      status: entry.status,
      // If an offer is active, return spot details
      offeredSpotId: entry.offeredSpotId || null,
      offerExpiresAt: entry.offerExpiresAt || null,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Join waiting list — only allowed when garage is full
router.post('/join', auth, async (req, res) => {
  try {
    const existing = await WaitingList.findOne({
      userId: req.user._id,
      status: { $in: ['waiting', 'offered'] }
    });
    if (existing) return res.status(400).json({ message: 'Already in queue' });

    // Block joining if any spots are available
    const availableCount = await ParkingSpot.countDocuments({ status: 'available' });
    if (availableCount > 0) {
      return res.status(400).json({
        message: 'Cannot join the waiting list. There are still available parking spots in the garage!'
      });
    }

    const count = await WaitingList.countDocuments({ status: { $in: ['waiting', 'offered'] } });
    const entry = await WaitingList.create({ userId: req.user._id, position: count + 1 });
    res.status(201).json(entry);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Leave waiting list
router.delete('/leave', auth, async (req, res) => {
  try {
    await WaitingList.findOneAndUpdate(
      { userId: req.user._id, status: { $in: ['waiting', 'offered'] } },
      { status: 'declined' }
    );
    res.json({ message: 'Left queue successfully' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ✅ Accept an offered spot
router.post('/accept', auth, async (req, res) => {
  try {
    const { duration = 1 } = req.body;

    const entry = await WaitingList.findOne({
      userId: req.user._id,
      status: 'offered'
    });

    if (!entry) {
      return res.status(400).json({ message: 'No active spot offer found for your account.' });
    }

    const result = await acceptOffer(entry._id, duration);

    if (!result.success) {
      return res.status(400).json({ message: result.message });
    }

    res.json({ message: 'Spot accepted and booked successfully!', booking: result.booking });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ❌ Decline an offered spot — cascades to next user
router.post('/decline', auth, async (req, res) => {
  try {
    const entry = await WaitingList.findOne({
      userId: req.user._id,
      status: 'offered'
    });

    if (!entry) {
      return res.status(400).json({ message: 'No active spot offer found for your account.' });
    }

    await declineOffer(entry._id);

    res.json({ message: 'Spot declined. You have been removed from the waiting list.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
