const router = require('express').Router();
const auth = require('../middleware/auth');
const Booking = require('../models/Booking');
const ParkingSpot = require('../models/ParkingSpot');
const User = require('../models/User');
const Notification = require('../models/Notification');

// Create booking
router.post('/', auth, async (req, res) => {
  try {
    const { spotId, duration } = req.body;

    const spot = await ParkingSpot.findOne({ spotId });
    if (!spot) return res.status(404).json({ message: 'Spot not found' });
    if (spot.status !== 'available') return res.status(400).json({ message: 'Spot is not available' });

    const cost = duration <= 1 ? 0 : (duration - 1) * 10;
    const startTime = new Date();
    const endTime = new Date(startTime.getTime() + duration * 60 * 60 * 1000);

    const booking = await Booking.create({
      userId: req.user._id,
      spotId,
      zone: spot.zone,
      duration,
      cost,
      startTime,
      endTime,
      status: 'active',
      qrCode: `AAST-${spotId}-${Date.now()}`,
    });

    // Update spot status
    await ParkingSpot.findOneAndUpdate(
      { spotId },
      { status: 'reserved', currentBookingId: booking._id, availableAt: endTime }
    );

    // Update user stats
    await User.findByIdAndUpdate(req.user._id, {
      $inc: { totalBookings: 1, totalSpent: cost },
    });

    // Create notification
    await Notification.create({
      userId: req.user._id,
      type: 'success',
      title: 'Booking Confirmed',
      message: `Your parking spot ${spotId} has been reserved for ${duration} hour${duration > 1 ? 's' : ''}`,
    });

    // Auto-complete after duration
    setTimeout(async () => {
      await Booking.findByIdAndUpdate(booking._id, { status: 'completed' });
      await ParkingSpot.findOneAndUpdate({ spotId }, { status: 'available', currentBookingId: null, availableAt: null });
      await Notification.create({
        userId: req.user._id,
        type: 'info',
        title: 'Booking Completed',
        message: `Thank you for using AAST Parking. Total: ${cost === 0 ? 'FREE' : cost + ' EGP'}`,
      });
    }, duration * 60 * 60 * 1000);

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

// Cancel booking
router.patch('/:id/cancel', auth, async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) return res.status(404).json({ message: 'Booking not found' });
    if (booking.userId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Unauthorized' });
    }

    await Booking.findByIdAndUpdate(req.params.id, { status: 'cancelled' });
    await ParkingSpot.findOneAndUpdate(
      { spotId: booking.spotId },
      { status: 'available', currentBookingId: null, availableAt: null }
    );

    res.json({ message: 'Booking cancelled' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
