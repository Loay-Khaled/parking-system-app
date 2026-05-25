const router = require('express').Router();
const auth = require('../middleware/auth');
const User = require('../models/User');

// Get profile
router.get('/', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select('-password');
    res.json(user);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Update profile
router.patch('/', auth, async (req, res) => {
  try {
    const { name, carPlate } = req.body;
    const user = await User.findByIdAndUpdate(
      req.user._id,
      { name, carPlate },
      { new: true }
    ).select('-password');
    res.json(user);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
