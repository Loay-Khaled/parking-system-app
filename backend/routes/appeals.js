const router = require('express').Router();
const sanitizeHtml = require('sanitize-html');
const auth = require('../middleware/auth');
const { requireAdmin } = require('../middleware/auth');
const Appeal = require('../models/Appeal');
const Transaction = require('../models/Transaction');
const User = require('../models/User');

const protectAdmin = [auth, requireAdmin];

// POST /api/appeals - Submit an appeal
router.post('/', auth, async (req, res) => {
  try {
    const { bookingId, transactionId, penaltyAmount, reason } = req.body;
    if (!bookingId || !transactionId || !penaltyAmount || !reason) {
      return res.status(400).json({ message: 'All fields are required' });
    }

    // Verify transaction exists, belongs to user, and is a penalty
    const transaction = await Transaction.findOne({
      _id: transactionId,
      userId: req.user._id,
      type: 'penalty',
    });

    if (!transaction) {
      return res.status(404).json({ message: 'Matching penalty transaction not found.' });
    }

    // Verify no existing pending appeal for this transaction
    const existing = await Appeal.findOne({
      transactionId,
      status: 'pending',
    });

    if (existing) {
      return res.status(400).json({ message: 'You already have a pending appeal for this penalty.' });
    }

    const pendingCount = await Appeal.countDocuments({
      userId: req.user._id,
      status: 'pending'
    });
    if (pendingCount >= 3) {
      return res.status(429).json({
        message: 'You already have 3 pending appeals. Wait for them to be resolved before filing more.'
      });
    }

    const cleanReason = sanitizeHtml(req.body.reason, {
      allowedTags: [],
      allowedAttributes: {}
    }).trim();

    if (!cleanReason || cleanReason.length < 20) {
      return res.status(400).json({
        message: 'Reason must be at least 20 characters.'
      });
    }
    if (cleanReason.length > 500) {
      return res.status(400).json({
        message: 'Reason must not exceed 500 characters.'
      });
    }

    const appeal = await Appeal.create({
      userId: req.user._id,
      bookingId,
      transactionId,
      penaltyAmount,
      reason: cleanReason,
      status: 'pending',
    });

    res.status(201).json(appeal);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/appeals/my - Get user's appeals
router.get('/my', auth, async (req, res) => {
  try {
    const appeals = await Appeal.find({ userId: req.user._id })
      .populate('bookingId')
      .populate('transactionId')
      .sort({ createdAt: -1 });
    res.json(appeals);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/appeals/:id - Get single appeal by ID
router.get('/:id', auth, async (req, res) => {
  try {
    const appeal = await Appeal.findById(req.params.id)
      .populate('bookingId', 'startTime endTime cost status')
      .populate('transactionId', 'amount createdAt description')
      .populate('resolvedBy', 'name email');

    if (!appeal) {
      return res.status(404).json({ message: 'Appeal not found.' });
    }

    // Users can only view their own appeals; admins can view any
    if (
      appeal.userId.toString() !== req.user._id.toString() &&
      !req.user.isAdmin
    ) {
      return res.status(403).json({ message: 'Access denied.' });
    }

    return res.json(appeal);
  } catch (err) {
    return res.status(500).json({ message: 'Server error.', error: err.message });
  }
});

// GET /api/appeals - Get all pending appeals (Admin only)
router.get('/', protectAdmin, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const total = await Appeal.countDocuments({ status: 'pending' });

    const appeals = await Appeal.find({ status: 'pending' })
      .populate('userId', 'name email')
      .populate('bookingId', 'startTime endTime')
      .populate('transactionId', 'amount createdAt')
      .sort({ createdAt: 1 })
      .skip(skip)
      .limit(limit);

    return res.json({
      appeals,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
        hasMore: page * limit < total
      }
    });
  } catch (err) {
    return res.status(500).json({ message: 'Server error.', error: err.message });
  }
});

// PATCH /api/appeals/:id/resolve - Resolve appeal (Admin only)
router.patch('/:id/resolve', protectAdmin, async (req, res) => {
  try {
    const { decision, adminNote } = req.body;
    if (!['approved', 'rejected'].includes(decision)) {
      return res.status(400).json({ message: 'Decision must be approved or rejected' });
    }

    const appeal = await Appeal.findById(appealId = req.params.id);
    if (!appeal) {
      return res.status(404).json({ message: 'Appeal not found' });
    }

    if (appeal.status !== 'pending') {
      return res.status(400).json({ message: 'Appeal has already been resolved' });
    }

    if (decision === 'approved') {
      // Find and update the user
      const user = await User.findById(appeal.userId);
      if (user) {
        user.walletBalance += appeal.penaltyAmount;
        user.activePenalties = Math.max(0, user.activePenalties - appeal.penaltyAmount);
        await user.save();

        // Create transaction record
        await Transaction.create({
          userId: user._id,
          amount: appeal.penaltyAmount,
          type: 'recharge',
          description: 'Penalty appeal approved — refunded',
        });
      }
    }

    appeal.status = decision;
    appeal.adminNote = adminNote || '';
    appeal.resolvedAt = new Date();
    appeal.resolvedBy = req.user._id;
    await appeal.save();

    res.json(appeal);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
