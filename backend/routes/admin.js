const router = require('express').Router();
const auth = require('../middleware/auth');
const { requireAdmin } = require('../middleware/auth');
const User = require('../models/User');
const { DISABILITY_TYPES } = require('../models/User');
const mongoose = require('mongoose');
const Transaction = require('../models/Transaction');
const Appeal = require('../models/Appeal');
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

// GET /api/admin/users — paginated list with search by _id or idNumber
router.get('/users', protect, async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(100, Math.max(1, parseInt(req.query.limit) || 20));
    const skip = (page - 1) * limit;
    const search = (req.query.search || '').trim();

    let filter = {};
    if (search) {
      // If it looks like a valid ObjectId, search by _id; otherwise by idNumber
      if (mongoose.Types.ObjectId.isValid(search)) {
        filter = { _id: search };
      } else {
        filter = { idNumber: { $regex: search, $options: 'i' } };
      }
    }

    const [users, total] = await Promise.all([
      User.find(filter)
        .select('-password')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      User.countDocuments(filter),
    ]);

    res.json({ users, total, page, limit, pages: Math.ceil(total / limit) });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/admin/users/:userId — full profile with recent bookings, transactions, appeals
router.get('/users/:userId', protect, async (req, res) => {
  try {
    const user = await User.findById(req.params.userId).select('-password');
    if (!user) return res.status(404).json({ message: 'User not found' });

    const [recentBookings, recentTransactions, openAppeals] = await Promise.all([
      Booking.find({ userId: req.params.userId })
        .select('spotId zone startTime endTime status cost duration')
        .sort({ createdAt: -1 })
        .limit(10),
      Transaction.find({ userId: req.params.userId })
        .select('type amount description createdAt')
        .sort({ createdAt: -1 })
        .limit(10),
      Appeal.countDocuments({ userId: req.params.userId, status: 'pending' }),
    ]);

    res.json({ user, recentBookings, recentTransactions, openAppeals });
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

// PATCH /api/admin/users/:userId/accessibility — grant or revoke accessibility permit
router.patch('/users/:userId/accessibility', protect, async (req, res) => {
  try {
    const { status, disabilityType, adminNote } = req.body;

    if (!['approved', 'none'].includes(status)) {
      return res.status(400).json({ message: 'status must be "approved" or "none".' });
    }

    if (adminNote && adminNote.length > 500) {
      return res.status(400).json({ message: 'adminNote must not exceed 500 characters.' });
    }

    if (status === 'approved' && !DISABILITY_TYPES.includes(disabilityType)) {
      return res.status(400).json({
        message: `disabilityType must be one of: ${DISABILITY_TYPES.join(', ')}.`,
      });
    }

    const user = await User.findById(req.params.userId);
    if (!user) return res.status(404).json({ message: 'User not found' });

    if (status === 'approved') {
      user.accessibilityPermit.status = 'approved';
      user.accessibilityPermit.disabilityType = disabilityType;
      user.accessibilityPermit.adminNote = adminNote || '';
      user.accessibilityPermit.reviewedAt = new Date();
      user.accessibilityPermit.reviewedBy = req.user._id;
      user.accessibilityPermit.notified = false;
      await user.save();

      // In-app notification to the user
      await Notification.create({
        userId: user._id,
        type: 'success',
        title: 'Accessibility Permit Granted',
        message: `An administrator has granted you an accessibility permit (${disabilityType}). You can now book accessibility spots.`,
      });
    } else {
      // Revoke: preserve reviewedBy/At, write lastRevokedBy/At
      user.accessibilityPermit.status = 'none';
      user.accessibilityPermit.disabilityType = null;
      user.accessibilityPermit.adminNote = adminNote || '';
      user.accessibilityPermit.notified = true;
      user.accessibilityPermit.lastRevokedBy = req.user._id;
      user.accessibilityPermit.lastRevokedAt = new Date();
      await user.save();

      // Cancel ALL active bookings on accessibility spots for this user
      const activeAccessibilityBookings = await Booking.find({
        userId: user._id,
        status: 'active',
      });

      for (const booking of activeAccessibilityBookings) {
        const spot = await ParkingSpot.findOne({ spotId: booking.spotId, isAccessibility: true });
        if (!spot) continue;

        booking.status = 'cancelled';
        await booking.save();

        await ParkingSpot.findOneAndUpdate(
          { spotId: booking.spotId },
          { status: 'available', currentBookingId: null, availableAt: null }
        );

        // Full refund to wallet
        await User.findByIdAndUpdate(user._id, {
          $inc: { walletBalance: booking.cost },
        });

        // Audit refund transaction
        await Transaction.create({
          userId: user._id,
          type: 'refund',
          amount: booking.cost,
          description: `Refund: booking ${booking.spotId} cancelled due to accessibility permit revocation by admin.`,
        });
      }

      // In-app notification to the user
      await Notification.create({
        userId: user._id,
        type: 'warning',
        title: 'Accessibility Permit Revoked',
        message: `Your accessibility permit has been revoked by an administrator.${activeAccessibilityBookings.length > 0 ? ' Any active accessibility bookings have been cancelled and refunded.' : ''}${adminNote ? ' Note: ' + adminNote : ''}`,
      });
    }

    const updatedUser = await User.findById(req.params.userId).select('-password');
    res.json({ message: `Permit ${status === 'approved' ? 'granted' : 'revoked'} successfully.`, user: updatedUser });
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

// GET /api/admin/analytics - Admin revenue analytics
router.get('/analytics', protect, async (req, res) => {
  try {
    const range = req.query.range || 'week';
    const now = new Date();
    let startDate;

    if (range === 'today') {
      startDate = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    } else if (range === 'month') {
      startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    } else {
      // default: week (7 days)
      startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    }

    const Transaction = require('../models/Transaction');

    const diffTime = Math.abs(now - startDate);
    const daysInRange = Math.max(1, Math.ceil(diffTime / (1000 * 60 * 60 * 24)));

    const [
      revenueTxs,
      penaltyTxs,
      bookingsCount,
      newUsersCount,
      dailyRevenueAgg,
      zoneBookingsAgg,
      topUsersAgg,
      peakHoursAgg
    ] = await Promise.all([
      Transaction.aggregate([
        { $match: { createdAt: { $gte: startDate }, type: { $in: ['payment', 'penalty'] } } },
        { $group: { _id: null, total: { $sum: '$amount' } } }
      ]),
      Transaction.aggregate([
        { $match: { createdAt: { $gte: startDate }, type: 'penalty' } },
        { $group: { _id: null, total: { $sum: '$amount' } } }
      ]),
      Booking.countDocuments({ createdAt: { $gte: startDate }, status: 'completed' }),
      User.countDocuments({ createdAt: { $gte: startDate }, isAdmin: { $ne: true } }),
      Transaction.aggregate([
        { $match: { createdAt: { $gte: startDate }, type: { $in: ['payment', 'penalty'] } } },
        {
          $group: {
            _id: { $dateToString: { format: "%Y-%m-%d", date: "$createdAt" } },
            revenue: { $sum: "$amount" }
          }
        },
        { $sort: { _id: 1 } }
      ]),
      Booking.aggregate([
        { $match: { createdAt: { $gte: startDate } } },
        {
          $group: {
            _id: "$zone",
            bookings: { $sum: 1 },
            revenue: { $sum: "$cost" }
          }
        }
      ]),
      Transaction.aggregate([
        { $match: { createdAt: { $gte: startDate }, type: { $in: ['payment', 'penalty'] } } },
        {
          $group: {
            _id: "$userId",
            totalSpent: { $sum: "$amount" }
          }
        },
        { $sort: { totalSpent: -1 } },
        { $limit: 5 },
        {
          $lookup: {
            from: "users",
            localField: "_id",
            foreignField: "_id",
            as: "userInfo"
          }
        },
        { $unwind: "$userInfo" }
      ]),
      Booking.aggregate([
        { $match: { createdAt: { $gte: startDate } } },
        {
          $group: {
            _id: { $hour: "$startTime" },
            bookingCount: { $sum: 1 }
          }
        },
        { $sort: { _id: 1 } }
      ])
    ]);

    const totalRevenue = revenueTxs.length > 0 ? revenueTxs[0].total : 0;
    const totalPenalties = penaltyTxs.length > 0 ? penaltyTxs[0].total : 0;
    const averageBookingCost = bookingsCount > 0 ? Number((totalRevenue / bookingsCount).toFixed(2)) : 0;

    const totalSpotsByZone = { A: 6, B: 6, C: 6 };
    const zoneBreakdown = ['A', 'B', 'C'].map(zone => {
      const match = zoneBookingsAgg.find(item => item._id === zone) || {};
      const bookings = match.bookings || 0;
      const revenue = match.revenue || 0;
      const spotsCount = totalSpotsByZone[zone] || 6;
      const rate = bookings / (spotsCount * daysInRange);
      const occupancyRate = Number(Math.min(1.0, rate).toFixed(2));
      return { zone, bookings, revenue, occupancyRate };
    });

    const dailyMap = {};
    dailyRevenueAgg.forEach(item => {
      dailyMap[item._id] = { date: item._id, revenue: item.revenue, bookings: 0 };
    });

    const dailyBookingsAgg = await Booking.aggregate([
      { $match: { createdAt: { $gte: startDate } } },
      {
        $group: {
          _id: { $dateToString: { format: "%Y-%m-%d", date: "$createdAt" } },
          bookingsCount: { $sum: 1 }
        }
      }
    ]);
    dailyBookingsAgg.forEach(item => {
      if (dailyMap[item._id]) {
        dailyMap[item._id].bookings = item.bookingsCount;
      } else {
        dailyMap[item._id] = { date: item._id, revenue: 0, bookings: item.bookingsCount };
      }
    });
    const dailyRevenueList = Object.values(dailyMap).sort((a, b) => a.date.localeCompare(b.date));

    const topUsers = topUsersAgg.map(item => ({
      userId: item._id,
      name: item.userInfo.name,
      email: item.userInfo.email,
      totalSpent: item.totalSpent,
      totalBookings: item.userInfo.totalBookings || 0
    }));

    const peakHours = [];
    for (let hr = 0; hr < 24; hr++) {
      const match = peakHoursAgg.find(item => item._id === hr);
      peakHours.push({
        hour: hr,
        bookingCount: match ? match.bookingCount : 0
      });
    }

    res.json({
      summary: {
        totalRevenue,
        totalBookings: bookingsCount,
        averageBookingCost,
        totalPenalties,
        newUsers: newUsersCount
      },
      dailyRevenue: dailyRevenueList,
      zoneBreakdown,
      topUsers,
      peakHours
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
