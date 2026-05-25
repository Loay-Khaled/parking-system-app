const router = require('express').Router();
const auth = require('../middleware/auth');
const ParkingSpot = require('../models/ParkingSpot');

// Get all spots
router.get('/', auth, async (req, res) => {
  try {
    const spots = await ParkingSpot.find().sort({ zone: 1, spotId: 1 });
    const available = spots.filter(s => s.status === 'available').length;
    res.json({ spots, availableCount: available, totalCount: spots.length });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Get spots by zone
router.get('/zone/:zone', auth, async (req, res) => {
  try {
    const spots = await ParkingSpot.find({ zone: req.params.zone.toUpperCase() });
    res.json(spots);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Get single spot
router.get('/:spotId', auth, async (req, res) => {
  try {
    const spot = await ParkingSpot.findOne({ spotId: req.params.spotId });
    if (!spot) return res.status(404).json({ message: 'Spot not found' });
    res.json(spot);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
