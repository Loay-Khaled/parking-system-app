const router = require('express').Router();
const crypto = require('crypto');
const auth = require('../middleware/auth');
const { requireAdmin } = require('../middleware/auth');
const Booking = require('../models/Booking');
const ParkingSpot = require('../models/ParkingSpot');
const User = require('../models/User');
const Notification = require('../models/Notification');
const { triggerQueueForSpot } = require('../services/queueService');

// Create booking
router.post('/', auth, async (req, res) => {
  try {
    const { spotId, duration } = req.body;

    const spot = await ParkingSpot.findOne({ spotId });
    if (!spot) return res.status(404).json({ message: 'Spot not found' });
    if (spot.status !== 'available') return res.status(400).json({ message: 'Spot is not available' });

    if (spot.isAccessibility) {
      // Re-fetch user fresh from DB to prevent race condition with concurrent permit revocation
      const freshUser = await User.findById(req.user._id);
      if (!freshUser || freshUser.accessibilityPermit.status !== 'approved') {
        return res.status(403).json({
          message: 'This spot is reserved for users with an approved accessibility permit.',
          requiresPermit: true
        });
      }
    }

    const cost = duration <= 1 ? 0 : (duration - 1) * 10;
    const startTime = new Date();
    const endTime = new Date(startTime.getTime() + duration * 60 * 60 * 1000);

    const booking = new Booking({
      userId: req.user._id,
      spotId,
      zone: spot.zone,
      duration,
      cost,
      startTime,
      endTime,
      status: 'active',
    });

    const qrPayload = crypto
      .createHmac('sha256', process.env.QR_SECRET)
      .update(booking._id.toString())
      .digest('hex');
    booking.qrCode = qrPayload;

    await booking.save();

    await ParkingSpot.findOneAndUpdate(
      { spotId },
      { status: 'reserved', currentBookingId: booking._id, availableAt: endTime }
    );

    await User.findByIdAndUpdate(req.user._id, {
      $inc: { totalBookings: 1, totalSpent: cost },
    });

    await Notification.create({
      userId: req.user._id,
      type: 'success',
      title: 'Booking Confirmed',
      message: `Your parking spot ${spotId} has been reserved for ${duration} hour${duration > 1 ? 's' : ''}`,
    });

    res.status(201).json(booking);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Get user bookings
router.get('/my', auth, async (req, res) => {
  try {
    const bookings = await Booking.find({ userId: req.user._id }).sort({ createdAt: -1 });
    res.json(bookings);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/bookings/pending-reminder - Get user's active expiring bookings
// IMPORTANT: must be declared BEFORE /:id to prevent Express matching 'pending-reminder' as an ObjectId
router.get('/pending-reminder', auth, async (req, res) => {
  try {
    const bookings = await Booking.find({
      userId: req.user._id,
      status: 'active',
      reminderSent: true,
      reminderAcknowledged: false,
    });
    res.json(bookings);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Get single booking
router.get('/:id', auth, async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) return res.status(404).json({ message: 'Booking not found' });
    res.json(booking);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Cancel booking — triggers FIFO queue after spot is freed
router.patch('/:id/cancel', auth, async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) return res.status(404).json({ message: 'Booking not found' });
    if (booking.userId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Unauthorized' });
    }

    const spotId = booking.spotId;

    await Booking.findByIdAndUpdate(req.params.id, { status: 'cancelled' });
    await ParkingSpot.findOneAndUpdate(
      { spotId },
      { status: 'available', currentBookingId: null, availableAt: null }
    );

    res.json({ message: 'Booking cancelled' });

    // 🔔 Trigger FIFO queue now that spot is free
    triggerQueueForSpot(spotId);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/bookings/checkin - (Admin only)
router.post('/checkin', auth, requireAdmin, async (req, res) => {
  try {
    const { bookingId, qrCode } = req.body;
    if (!bookingId || !qrCode) return res.status(400).json({ message: 'bookingId and qrCode are required' });

    const booking = await Booking.findById(bookingId);
    if (!booking) return res.status(404).json({ message: 'Booking not found' });

    const expectedQr = crypto
      .createHmac('sha256', process.env.QR_SECRET)
      .update(booking._id.toString())
      .digest('hex');

    if (qrCode !== expectedQr) {
      return res.status(401).json({ message: 'Invalid QR code. Check-in denied.' });
    }

    if (booking.status !== 'active') {
      return res.status(400).json({ message: 'Booking is not active' });
    }

    if (booking.isCheckedIn) {
      return res.status(400).json({ message: 'Booking is already checked in' });
    }

    // Grace period validation (+/- 15 minutes of startTime)
    const now = new Date();
    const start = new Date(booking.startTime);
    const fifteenMinutes = 15 * 60 * 1000;
    const diff = Math.abs(now.getTime() - start.getTime());

    if (diff > fifteenMinutes && now.getTime() > start.getTime() + fifteenMinutes) {
      // Exceeded grace period, cancel as no-show
      booking.noShowCancelled = true;
      booking.status = 'cancelled';
      await booking.save();

      await ParkingSpot.findOneAndUpdate(
        { spotId: booking.spotId },
        { status: 'available', currentBookingId: null, availableAt: null }
      );

      // Trigger waiting list queue
      await triggerQueueForSpot(booking.spotId);

      return res.status(400).json({
        message: 'Check-in failed: grace period exceeded. Booking has been cancelled as a no-show.',
        booking,
      });
    }

    // Valid check-in
    booking.isCheckedIn = true;
    booking.checkedInAt = now;
    await booking.save();

    await ParkingSpot.findOneAndUpdate(
      { spotId: booking.spotId },
      { status: 'occupied' }
    );

    res.json(booking);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/bookings/checkout - (Admin only)
router.post('/checkout', auth, requireAdmin, async (req, res) => {
  try {
    const { bookingId } = req.body;
    if (!bookingId) return res.status(400).json({ message: 'bookingId is required' });

    const booking = await Booking.findById(bookingId);
    if (!booking) return res.status(404).json({ message: 'Booking not found' });

    if (!booking.isCheckedIn) {
      return res.status(400).json({ message: 'Booking is not checked in' });
    }

    if (booking.isCheckedOut) {
      return res.status(400).json({ message: 'Booking is already checked out' });
    }

    const now = new Date();
    booking.isCheckedOut = true;
    booking.checkedOutAt = now;
    booking.status = 'completed';
    await booking.save();

    // Free the spot
    await ParkingSpot.findOneAndUpdate(
      { spotId: booking.spotId },
      { status: 'available', currentBookingId: null, availableAt: null }
    );

    // Overstay checks
    let penaltyAmount = 0;
    let overstayHours = 0;
    const end = new Date(booking.endTime);

    if (now.getTime() > end.getTime()) {
      // Overstayed! Calculate hours (rounded up)
      overstayHours = Math.ceil((now.getTime() - end.getTime()) / (60 * 60 * 1000));
      penaltyAmount = overstayHours * 20;

      // Charge penalty
      const user = await User.findById(booking.userId);
      if (user) {
        const actualDeduction = Math.min(penaltyAmount, user.walletBalance);
        const remainingPenalty = penaltyAmount - actualDeduction;

        user.walletBalance = Math.max(0, user.walletBalance - penaltyAmount);
        user.activePenalties += penaltyAmount;
        await user.save();

        // Transaction records the FULL penalty amount for audit purposes
        await Transaction.create({
          userId: user._id,
          type: 'penalty',
          amount: penaltyAmount,
          description: `Overstay penalty: ${overstayHours} hour(s). \nDeducted: ${actualDeduction} EGP. \nRemaining debt: ${remainingPenalty} EGP.`
        });
      }
    }

    // Trigger waiting list queue
    await triggerQueueForSpot(booking.spotId);

    res.json({
      booking,
      overstayHours,
      penaltyAmount,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});


// PATCH /api/bookings/:id/acknowledge-reminder - Acknowledge a reminder
router.patch('/:id/acknowledge-reminder', auth, async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) {
      return res.status(404).json({ message: 'Booking not found.' });
    }
    if (booking.userId.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        message: 'You are not authorized to acknowledge this booking.'
      });
    }
    booking.reminderAcknowledged = true;
    await booking.save();
    return res.json({ success: true, booking });
  } catch (err) {
    return res.status(500).json({ message: 'Server error.', error: err.message });
  }
});

module.exports = router;
