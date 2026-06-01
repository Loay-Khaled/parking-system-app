const router = require('express').Router();
const auth = require('../middleware/auth');
const Booking = require('../models/Booking');
const ParkingSpot = require('../models/ParkingSpot');

// GET /api/recommendations/spot - Get smart spot recommendations
router.get('/spot', auth, async (req, res) => {
  try {
    // 1. Get all completed bookings for user
    const userBookings = await Booking.find({ userId: req.user._id, status: 'completed' });

    // Get all currently available parking spots
    const excludeAccessibility = req.user.accessibilityPermit?.status !== 'approved';
    const query = {
      status: 'available',
      ...(excludeAccessibility && { isAccessibility: false }),
    };
    const availableSpots = await ParkingSpot.find(query);

    // If user has no booking history, return up to 3 random available spots
    if (userBookings.length === 0) {
      const shuffled = [...availableSpots].sort(() => 0.5 - Math.random());
      const recommendedSpots = shuffled.slice(0, 3).map(spot => ({
        _id: spot._id,
        spotId: spot.spotId,
        zone: spot.zone,
        floor: spot.floor,
        status: spot.status,
        previouslyUsed: false,
      }));

      return res.json({
        preferredZone: null,
        zoneCounts: { A: 0, B: 0, C: 0 },
        recommendedSpots,
        message: "New here? Here are available spots",
      });
    }

    // 2. Count zone frequency in history
    const zoneCounts = { A: 0, B: 0, C: 0 };
    userBookings.forEach(b => {
      if (zoneCounts[b.zone] !== undefined) {
        zoneCounts[b.zone]++;
      }
    });

    // 3. Count available spots per zone to serve as tie-breaker
    const availableCounts = { A: 0, B: 0, C: 0 };
    availableSpots.forEach(s => {
      if (availableCounts[s.zone] !== undefined) {
        availableCounts[s.zone]++;
      }
    });

    // Determine preferred zone (with available spot counts as tie-breaker)
    const zonesSorted = ['A', 'B', 'C'].sort((z1, z2) => {
      if (zoneCounts[z1] !== zoneCounts[z2]) {
        return zoneCounts[z2] - zoneCounts[z1]; // Descending booking frequency
      }
      return availableCounts[z2] - availableCounts[z1]; // Descending availability counts
    });

    const preferredZone = zonesSorted[0];

    // 4. Within preferred zone, find available spots and check if previously used
    const previouslyBookedSpots = new Set(userBookings.map(b => b.spotId));
    const spotsInPreferredZone = availableSpots.filter(s => s.zone === preferredZone);

    const recommendedSpots = spotsInPreferredZone.map(spot => ({
      _id: spot._id,
      spotId: spot.spotId,
      zone: spot.zone,
      floor: spot.floor,
      status: spot.status,
      previouslyUsed: previouslyBookedSpots.has(spot.spotId),
    }));

    // Sort so previously used spots come first
    recommendedSpots.sort((s1, s2) => {
      if (s1.previouslyUsed && !s2.previouslyUsed) return -1;
      if (!s1.previouslyUsed && s2.previouslyUsed) return 1;
      return 0;
    });

    res.json({
      preferredZone,
      zoneCounts,
      recommendedSpots,
      message: `You usually park in Zone ${preferredZone}`,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
