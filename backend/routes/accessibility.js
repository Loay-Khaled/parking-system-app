const router = require('express').Router();
const auth = require('../middleware/auth');
const { requireAdmin } = require('../middleware/auth');
const User = require('../models/User');
const ParkingSpot = require('../models/ParkingSpot');

const protectAdmin = [auth, requireAdmin];

// POST /api/accessibility/apply - DISABLED: Permits are now assigned exclusively by admins.
router.post('/apply', auth, async (req, res) => {
  return res.status(403).json({
    message: 'Self-application is no longer available. Accessibility permits are assigned exclusively by an administrator. Please contact the parking office.',
  });
});

// GET /api/accessibility/my-permit - Returns current user's permit status details
router.get('/my-permit', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).json({ message: 'User not found.' });

    if (user.accessibilityPermit.status === 'none') {
      return res.json({ status: 'none', message: 'No permit on file.' });
    }

    res.json(user.accessibilityPermit);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PATCH /api/accessibility/my-permit/dismiss-notification - DISABLED (no longer needed)
router.patch('/my-permit/dismiss-notification', auth, async (req, res) => {
  return res.status(410).json({ message: 'This endpoint is no longer available.' });
});

// GET /api/accessibility/applications - Fetch all pending applications (Admin only)
router.get('/applications', protectAdmin, async (req, res) => {
  try {
    const users = await User.find({ 'accessibilityPermit.status': 'pending' })
      .select('name email idNumber accessibilityPermit')
      .sort({ 'accessibilityPermit.submittedAt': 1 });

    res.json(users);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PATCH /api/accessibility/applications/:userId/resolve - Approve or reject application (Admin only)
router.patch('/applications/:userId/resolve', protectAdmin, async (req, res) => {
  try {
    const { decision, adminNote } = req.body;

    if (!['approved', 'rejected'].includes(decision)) {
      return res.status(400).json({ message: 'Decision must be approved or rejected.' });
    }

    const user = await User.findById(req.params.userId);
    if (!user) return res.status(404).json({ message: 'User not found.' });

    user.accessibilityPermit.status = decision;
    user.accessibilityPermit.reviewedAt = new Date();
    user.accessibilityPermit.reviewedBy = req.user._id;
    user.accessibilityPermit.adminNote = adminNote || '';
    user.accessibilityPermit.notified = false;

    await user.save();
    res.json({
      message: `Permit ${decision}.`,
      permit: user.accessibilityPermit,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PATCH /api/accessibility/spots/:spotId/toggle - Toggle accessibility status on a spot (Admin only)
router.patch('/spots/:spotId/toggle', protectAdmin, async (req, res) => {
  try {
    const { isAccessibility, accessibilityLabel } = req.body;

    if (typeof isAccessibility !== 'boolean') {
      return res.status(400).json({ message: 'isAccessibility must be a boolean.' });
    }

    const spot = await ParkingSpot.findOne({ spotId: req.params.spotId });
    if (!spot) return res.status(404).json({ message: 'Parking spot not found.' });

    spot.isAccessibility = isAccessibility;
    spot.accessibilityLabel = isAccessibility ? (accessibilityLabel || 'Wheelchair Access') : '';
    spot.updatedAt = new Date();

    await spot.save();
    res.json(spot);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
