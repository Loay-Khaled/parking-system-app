const router = require('express').Router();
const auth = require('../middleware/auth');
const Booking = require('../models/Booking');

// GET /api/analytics/hourly-heatmap - Get hourly zone busyness heatmap
router.get('/hourly-heatmap', auth, async (req, res) => {
  try {
    const completedBookings = await Booking.find({ status: 'completed' });

    if (completedBookings.length < 5) {
      return res.json({ insufficient: true });
    }

    const zoneHourCounts = {
      A: Array(24).fill(0),
      B: Array(24).fill(0),
      C: Array(24).fill(0),
    };

    const uniqueDays = new Set();

    completedBookings.forEach(booking => {
      const start = new Date(booking.startTime);
      const end = new Date(booking.endTime);
      const zone = booking.zone;

      if (!zoneHourCounts[zone]) return;

      // Keep track of total unique days
      uniqueDays.add(start.toDateString());

      // Walk through booking hours
      let current = new Date(start);
      current.setMinutes(0, 0, 0);

      while (current <= end) {
        const hour = current.getHours();
        zoneHourCounts[zone][hour]++;
        // Increment by 1 hour
        current.setHours(current.getHours() + 1);
      }
    });

    const daysCount = Math.max(1, uniqueDays.size);

    const zonesHeatmap = {
      A: {},
      B: {},
      C: {},
    };

    const peakHour = { A: 0, B: 0, C: 0 };

    ['A', 'B', 'C'].forEach(zone => {
      let maxVal = -1;
      let bestHour = 9; // Default peak hour fallback

      for (let hr = 0; hr < 24; hr++) {
        const avg = Number((zoneHourCounts[zone][hr] / daysCount).toFixed(2));
        zonesHeatmap[zone][hr] = avg;

        if (avg > maxVal) {
          maxVal = avg;
          bestHour = hr;
        }
      }
      peakHour[zone] = bestHour;
    });

    res.json({
      zones: zonesHeatmap,
      peakHour,
      currentHour: new Date().getHours(),
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
