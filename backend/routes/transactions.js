const router = require('express').Router();
const auth = require('../middleware/auth');
const Transaction = require('../models/Transaction');

router.get('/', auth, async (req, res) => {
  try {
    const filter = { userId: req.user._id };

    if (req.query.type) {
      const allowedTypes = ['recharge', 'payment', 'penalty'];
      if (!allowedTypes.includes(req.query.type)) {
        return res.status(400).json({
          message: 'Invalid type filter. Use: recharge, payment, or penalty.'
        });
      }
      filter.type = req.query.type;
    }

    const transactions = await Transaction.find(filter)
      .sort({ createdAt: -1 })
      .limit(50);

    return res.json(transactions);
  } catch (err) {
    return res.status(500).json({ message: 'Server error.', error: err.message });
  }
});

module.exports = router;
