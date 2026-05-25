/**
 * FIFO Queue Service
 * When a spot becomes available, this service automatically finds the first
 * 'waiting' user in the queue and offers them the spot for 5 minutes.
 * If they decline or don't respond, it cascades to the next user.
 */

const WaitingList = require('../models/WaitingList');
const ParkingSpot = require('../models/ParkingSpot');
const Booking = require('../models/Booking');
const Notification = require('../models/Notification');
const User = require('../models/User');

const OFFER_DURATION_MS = 5 * 60 * 1000; // 5 minutes

/**
 * Called whenever a spot transitions to 'available'.
 * Finds the first waiting user and offers them the spot.
 */
async function triggerQueueForSpot(spotId) {
  try {
    // Verify spot is still available
    const spot = await ParkingSpot.findOne({ spotId, status: 'available' });
    if (!spot) return; // Already taken or doesn't exist

    // Find the first user who is actively 'waiting' (not offered/accepted/etc.)
    const nextEntry = await WaitingList.findOne({ status: 'waiting' }).sort({ position: 1 });
    if (!nextEntry) return; // No one in queue

    const offerExpiresAt = new Date(Date.now() + OFFER_DURATION_MS);

    // Mark the entry as 'offered' with spot details and expiry time
    await WaitingList.findByIdAndUpdate(nextEntry._id, {
      status: 'offered',
      offeredSpotId: spotId,
      offerExpiresAt,
    });

    // Lock the spot so no one else books it while the offer is pending
    await ParkingSpot.findOneAndUpdate(
      { spotId },
      { status: 'reserved', currentBookingId: null, availableAt: offerExpiresAt }
    );

    // Send an in-app notification to the user
    await Notification.create({
      userId: nextEntry.userId,
      type: 'warning',
      title: '🚗 Parking Spot Available!',
      message: `Spot ${spotId} is now available for you! You have 5 minutes to accept or decline. Open the Waiting List screen now.`,
    });

    console.log(`[Queue] Offered spot ${spotId} to user ${nextEntry.userId}. Expires: ${offerExpiresAt}`);

    // Auto-expire: if user doesn't respond in 5 min, cascade to next user
    setTimeout(async () => {
      await expireOffer(nextEntry._id, spotId);
    }, OFFER_DURATION_MS);

  } catch (err) {
    console.error('[Queue] triggerQueueForSpot error:', err.message);
  }
}

/**
 * Expires an offer and cascades to the next user in queue.
 */
async function expireOffer(entryId, spotId) {
  try {
    const entry = await WaitingList.findById(entryId);
    if (!entry || entry.status !== 'offered') return; // Already handled (accepted/declined)

    // Mark as expired
    await WaitingList.findByIdAndUpdate(entryId, { status: 'expired' });

    // Notify user their offer expired
    await Notification.create({
      userId: entry.userId,
      type: 'info',
      title: 'Offer Expired',
      message: `Your 5-minute window to accept spot ${spotId} has expired. The spot has been offered to the next person in queue.`,
    });

    // Release the spot back to available, then cascade to next user
    await ParkingSpot.findOneAndUpdate(
      { spotId },
      { status: 'available', currentBookingId: null, availableAt: null }
    );

    console.log(`[Queue] Offer for spot ${spotId} expired for user ${entry.userId}. Cascading...`);

    // Cascade: try next user in the queue
    await triggerQueueForSpot(spotId);

  } catch (err) {
    console.error('[Queue] expireOffer error:', err.message);
  }
}

/**
 * Called when a user declines an offered spot.
 * Marks them as declined, releases the spot, offers to next user.
 */
async function declineOffer(entryId) {
  try {
    const entry = await WaitingList.findById(entryId);
    if (!entry || entry.status !== 'offered') return null;

    const spotId = entry.offeredSpotId;

    // Mark as declined
    await WaitingList.findByIdAndUpdate(entryId, { status: 'declined' });

    // Release the spot
    await ParkingSpot.findOneAndUpdate(
      { spotId },
      { status: 'available', currentBookingId: null, availableAt: null }
    );

    await Notification.create({
      userId: entry.userId,
      type: 'info',
      title: 'Spot Declined',
      message: `You declined spot ${spotId}. You have been removed from the waiting list.`,
    });

    console.log(`[Queue] User ${entry.userId} declined spot ${spotId}. Cascading...`);

    // Cascade to next user
    await triggerQueueForSpot(spotId);

    return spotId;
  } catch (err) {
    console.error('[Queue] declineOffer error:', err.message);
    return null;
  }
}

/**
 * Called when a user accepts an offered spot.
 * Creates a real booking and removes them from the queue.
 */
async function acceptOffer(entryId, duration = 1) {
  try {
    const entry = await WaitingList.findById(entryId);
    if (!entry || entry.status !== 'offered') {
      return { success: false, message: 'No active offer found' };
    }

    // Check offer not expired
    if (new Date() > entry.offerExpiresAt) {
      await WaitingList.findByIdAndUpdate(entryId, { status: 'expired' });
      return { success: false, message: 'Offer has expired' };
    }

    const spotId = entry.offeredSpotId;
    const spot = await ParkingSpot.findOne({ spotId });
    if (!spot) return { success: false, message: 'Spot no longer exists' };

    const cost = duration <= 1 ? 0 : (duration - 1) * 10;
    const startTime = new Date();
    const endTime = new Date(startTime.getTime() + duration * 60 * 60 * 1000);

    // Create the booking
    const booking = await Booking.create({
      userId: entry.userId,
      spotId,
      zone: spot.zone,
      duration,
      cost,
      startTime,
      endTime,
      status: 'active',
      qrCode: `AAST-${spotId}-${Date.now()}`,
    });

    // Update spot status to reserved with new booking
    await ParkingSpot.findOneAndUpdate(
      { spotId },
      { status: 'reserved', currentBookingId: booking._id, availableAt: endTime }
    );

    // Update user stats
    await User.findByIdAndUpdate(entry.userId, {
      $inc: { totalBookings: 1, totalSpent: cost },
    });

    // Mark queue entry as accepted
    await WaitingList.findByIdAndUpdate(entryId, { status: 'accepted' });

    // Confirm notification
    await Notification.create({
      userId: entry.userId,
      type: 'success',
      title: '✅ Booking Confirmed!',
      message: `You've successfully reserved spot ${spotId} for ${duration} hour${duration > 1 ? 's' : ''}. Cost: ${cost === 0 ? 'FREE' : cost + ' EGP'}`,
    });

    // Auto-complete after duration — also trigger queue check afterward
    setTimeout(async () => {
      await Booking.findByIdAndUpdate(booking._id, { status: 'completed' });
      await ParkingSpot.findOneAndUpdate({ spotId }, { status: 'available', currentBookingId: null, availableAt: null });
      await Notification.create({
        userId: entry.userId,
        type: 'info',
        title: 'Booking Completed',
        message: `Thank you for using AAST Parking. Total: ${cost === 0 ? 'FREE' : cost + ' EGP'}`,
      });
      // Trigger queue again in case others are waiting
      await triggerQueueForSpot(spotId);
    }, duration * 60 * 60 * 1000);

    console.log(`[Queue] User ${entry.userId} accepted spot ${spotId}. Booking ${booking._id} created.`);
    return { success: true, booking };

  } catch (err) {
    console.error('[Queue] acceptOffer error:', err.message);
    return { success: false, message: err.message };
  }
}

module.exports = { triggerQueueForSpot, expireOffer, declineOffer, acceptOffer };
