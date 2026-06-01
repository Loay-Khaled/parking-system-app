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

// Get nearest available spot
router.get('/nearest', auth, async (req, res) => {
  try {
    const refX = parseFloat(req.query.x);
    const refY = parseFloat(req.query.y);

    if (isNaN(refX) || isNaN(refY)) {
      return res.status(400).json({ message: 'Invalid or missing reference coordinates x, y' });
    }

    const excludeAccessibility = req.user.accessibilityPermit?.status !== 'approved';
    const query = {
      status: 'available',
      ...(excludeAccessibility && { isAccessibility: false }),
    };
    const availableSpots = await ParkingSpot.find(query);
    if (availableSpots.length === 0) {
      return res.status(404).json({ message: 'No available parking spots found' });
    }

    let nearestSpot = null;
    let minDistance = Infinity;

    for (const spot of availableSpots) {
      const dx = (spot.x || 0) - refX;
      const dy = (spot.y || 0) - refY;
      const distance = Math.sqrt(dx * dx + dy * dy);
      if (distance < minDistance) {
        minDistance = distance;
        nearestSpot = spot;
      }
    }

    res.json(nearestSpot);
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
