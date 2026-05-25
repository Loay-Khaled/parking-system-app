const router = require('express').Router();
const auth = require('../middleware/auth');
const { requireAdmin } = require('../middleware/auth');
const User = require('../models/User');
const Booking = require('../models/Booking');
const ParkingSpot = require('../models/ParkingSpot');
const Notification = require('../models/Notification');

const protect = [auth, requireAdmin];

// GET /api/admin/stats
router.get('/stats', protect, async (req, res) => {
  try {
    const [
      totalUsers,
      totalBookings,
      activeBookings,
      revenueResult,
      spots,
    ] = await Promise.all([
      User.countDocuments({ isAdmin: { $ne: true } }),
      Booking.countDocuments(),
      Booking.countDocuments({ status: 'active' }),
      Booking.aggregate([
        { $match: { status: { $in: ['completed', 'active'] } } },
        { $group: { _id: null, total: { $sum: '$cost' } } },
      ]),
      ParkingSpot.find(),
    ]);

    const totalRevenue = revenueResult.length > 0 ? revenueResult[0].total : 0;
    const availableSpots = spots.filter(s => s.status === 'available').length;
    const occupiedSpots = spots.filter(s => s.status === 'occupied').length;
    const reservedSpots = spots.filter(s => s.status === 'reserved').length;

    res.json({
      totalUsers,
      totalBookings,
      activeBookings,
      totalRevenue,
      spots: {
        total: spots.length,
        available: availableSpots,
        occupied: occupiedSpots,
        reserved: reservedSpots,
      },
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/admin/users
router.get('/users', protect, async (req, res) => {
  try {
    const users = await User.find().select('-password').sort({ createdAt: -1 });
    res.json(users);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// DELETE /api/admin/users/:id
router.delete('/users/:id', protect, async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ message: 'User not found' });
    if (user.isAdmin) return res.status(400).json({ message: 'Cannot delete an admin account' });

    await Booking.deleteMany({ userId: req.params.id });
    await Notification.deleteMany({ userId: req.params.id });
    await User.findByIdAndDelete(req.params.id);

    res.json({ message: 'User and their data deleted successfully' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/admin/bookings
router.get('/bookings', protect, async (req, res) => {
  try {
    const bookings = await Booking.find()
      .populate('userId', 'name email')
      .sort({ createdAt: -1 });
    res.json(bookings);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PATCH /api/admin/bookings/:id/cancel
router.patch('/bookings/:id/cancel', protect, async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id).populate('userId', 'name email');
    if (!booking) return res.status(404).json({ message: 'Booking not found' });
    if (booking.status !== 'active') {
      return res.status(400).json({ message: 'Only active bookings can be cancelled' });
    }

    booking.status = 'cancelled';
    await booking.save();

    await ParkingSpot.findOneAndUpdate(
      { spotId: booking.spotId },
      { status: 'available', currentBookingId: null, availableAt: null, updatedAt: new Date() }
    );

    await Notification.create({
      userId: booking.userId._id,
      type: 'warning',
      title: 'Booking Cancelled by Admin',
      message: `Your booking for spot ${booking.spotId} has been cancelled by an administrator.`,
    });

    res.json({ message: 'Booking cancelled successfully', booking });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/admin/spots
router.get('/spots', protect, async (req, res) => {
  try {
    const spots = await ParkingSpot.find().sort({ zone: 1, spotId: 1 });
    res.json(spots);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PATCH /api/admin/spots/:spotId/status
router.patch('/spots/:spotId/status', protect, async (req, res) => {
  try {
    const { status } = req.body;
    const validStatuses = ['available', 'occupied', 'reserved'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ message: 'Invalid status. Use: available, occupied, or reserved' });
    }

    const spot = await ParkingSpot.findOneAndUpdate(
      { spotId: req.params.spotId },
      { status, updatedAt: new Date() },
      { new: true }
    );
    if (!spot) return res.status(404).json({ message: 'Spot not found' });

    res.json({ message: 'Spot status updated', spot });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/admin/notifications/send
router.post('/notifications/send', protect, async (req, res) => {
  try {
    const { userId, title, message, type } = req.body;
    if (!title || !message) {
      return res.status(400).json({ message: 'Title and message are required' });
    }
    const notifType = ['success', 'info', 'warning', 'error'].includes(type) ? type : 'info';

    if (userId === 'all') {
      const users = await User.find({ isAdmin: { $ne: true } }).select('_id');
      const notifications = users.map(u => ({
        userId: u._id,
        type: notifType,
        title,
        message,
      }));
      await Notification.insertMany(notifications);
      return res.json({ message: `Notification sent to ${notifications.length} users` });
    }

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: 'User not found' });

    await Notification.create({ userId, type: notifType, title, message });
    res.json({ message: 'Notification sent successfully' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
