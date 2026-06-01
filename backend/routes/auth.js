const router = require('express').Router();
const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Register
router.post('/register', async (req, res) => {
  try {
    const { name, email, password, carPlate, idNumber } = req.body;
    if (!name || !email || !password || !carPlate || !idNumber) {
      return res.status(400).json({ message: 'All fields are required' });
    }
    const existingEmail = await User.findOne({ email });
    if (existingEmail) return res.status(400).json({ message: 'Email already registered' });

    const existingId = await User.findOne({ idNumber });
    if (existingId) return res.status(400).json({ message: 'ID Number already registered' });

    const Vehicle = require('../models/Vehicle');
    const existingPlate = await Vehicle.findOne({ licensePlate: carPlate.toUpperCase() });
    if (existingPlate) return res.status(400).json({ message: 'A vehicle with this license plate is already registered' });

    const user = await User.create({ name, email, password, carPlate, idNumber });

    await Vehicle.create({
      userId: user._id,
      licensePlate: carPlate.toUpperCase(),
      brand: 'Default',
      model: 'Default',
      color: 'White',
    });

    const token = jwt.sign({ userId: user._id }, process.env.JWT_SECRET, { expiresIn: '30d' });

    res.status(201).json({
      token,
      user: { id: user._id, name: user.name, email: user.email, carPlate: user.carPlate, idNumber: user.idNumber },
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(400).json({ message: 'Invalid email or password' });

    const isMatch = await user.comparePassword(password);
    if (!isMatch) return res.status(400).json({ message: 'Invalid email or password' });

    const token = jwt.sign({ userId: user._id, isAdmin: user.isAdmin }, process.env.JWT_SECRET, { expiresIn: '30d' });
    res.json({
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        carPlate: user.carPlate,
        idNumber: user.idNumber,
        totalBookings: user.totalBookings,
        totalSpent: user.totalSpent,
        activePenalties: user.activePenalties,
        isAdmin: user.isAdmin,
      },
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
