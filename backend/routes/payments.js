const router = require('express').Router();
const auth = require('../middleware/auth');
const User = require('../models/User');
const Transaction = require('../models/Transaction');

// 1. Recharge Endpoint
// POST /api/payments/recharge
// Takes user ID (optional, defaults to logged-in user) and amount
router.post('/recharge', auth, async (req, res) => {
  try {
    const { amount } = req.body;
    const userId = req.body.userId || req.user._id;

    if (!amount || typeof amount !== 'number' || amount <= 0) {
      return res.status(400).json({ message: 'Invalid recharge amount' });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Add to user's walletBalance
    user.walletBalance = (user.walletBalance || 0) + amount;
    await user.save();

    // Create a recharge transaction record
    const transaction = await Transaction.create({
      userId,
      amount,
      type: 'recharge',
      description: `Wallet recharge of ${amount.toFixed(2)} EGP`,
    });

    res.json({
      message: 'Recharge successful',
      walletBalance: user.walletBalance,
      transaction,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// 2. Pay Endpoint
// POST /api/payments/pay
// Takes user ID (optional, defaults to logged-in user) and booking cost
router.post('/pay', auth, async (req, res) => {
  try {
    const cost = req.body.cost !== undefined ? req.body.cost : req.body.amount;
    const userId = req.body.userId || req.user._id;

    if (cost === undefined || typeof cost !== 'number' || cost < 0) {
      return res.status(400).json({ message: 'Invalid payment amount' });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Check if wallet balance is sufficient
    if (user.walletBalance < cost) {
      return res.status(400).json({ message: 'Insufficient funds' });
    }

    // Deduct cost
    user.walletBalance -= cost;
    await user.save();

    // Create a payment transaction record
    const transaction = await Transaction.create({
      userId,
      amount: cost,
      type: 'payment',
      description: `Payment of ${cost.toFixed(2)} EGP for booking`,
    });

    res.json({
      message: 'Payment successful',
      walletBalance: user.walletBalance,
      transaction,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// 3. History Endpoint
// GET /api/payments/history
// Fetches the transaction history for the user
router.get('/history', auth, async (req, res) => {
  try {
    const userId = req.query.userId || req.user._id;
    const transactions = await Transaction.find({ userId }).sort({ createdAt: -1 });
    res.json(transactions);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
