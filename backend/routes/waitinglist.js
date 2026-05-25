const router = require('express').Router();
const auth = require('../middleware/auth');
const WaitingList = require('../models/WaitingList');

// Get user position in queue
router.get('/my', auth, async (req, res) => {
  try {
    const entry = await WaitingList.findOne({ userId: req.user._id, status: 'waiting' });
    const total = await WaitingList.countDocuments({ status: 'waiting' });
    res.json({ inQueue: !!entry, position: entry ? entry.position : null, totalWaiting: total });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Join waiting list
router.post('/join', auth, async (req, res) => {
  try {
    const existing = await WaitingList.findOne({ userId: req.user._id, status: 'waiting' });
    if (existing) return res.status(400).json({ message: 'Already in queue' });

    const count = await WaitingList.countDocuments({ status: 'waiting' });
    const entry = await WaitingList.create({ userId: req.user._id, position: count + 1 });
    res.status(201).json(entry);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Leave waiting list
router.delete('/leave', auth, async (req, res) => {
  try {
    await WaitingList.findOneAndDelete({ userId: req.user._id, status: 'waiting' });
    res.json({ message: 'Left queue successfully' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
