const router = require('express').Router();
const auth = require('../middleware/auth');
const Vehicle = require('../models/Vehicle');

// POST /api/vehicles - Add a new vehicle profile
router.post('/', auth, async (req, res) => {
  try {
    const { licensePlate, brand, model, color } = req.body;
    if (!licensePlate || !brand || !model || !color) {
      return res.status(400).json({ message: 'All fields are required' });
    }

    // Check if vehicle with same license plate already exists
    const existing = await Vehicle.findOne({ licensePlate: licensePlate.toUpperCase() });
    if (existing) {
      return res.status(400).json({ message: 'A vehicle with this license plate is already registered' });
    }

    const vehicle = await Vehicle.create({
      userId: req.user._id,
      licensePlate: licensePlate.toUpperCase(),
      brand,
      model,
      color,
    });

    res.status(201).json(vehicle);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/vehicles - Fetch all vehicles registered to the logged-in user
router.get('/', auth, async (req, res) => {
  try {
    const vehicles = await Vehicle.find({ userId: req.user._id });
    res.json(vehicles);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// DELETE /api/vehicles/:id - Delete a specific vehicle profile by its ID
router.delete('/:id', auth, async (req, res) => {
  try {
    const vehicle = await Vehicle.findOneAndDelete({
      _id: req.params.id,
      userId: req.user._id,
    });

    if (!vehicle) {
      return res.status(404).json({ message: 'Vehicle not found or unauthorized' });
    }

    res.json({ message: 'Vehicle profile deleted successfully' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
