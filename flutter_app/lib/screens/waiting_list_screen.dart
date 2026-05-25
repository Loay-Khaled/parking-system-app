import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/api_constants.dart';
import '../theme/app_theme.dart';

class WaitingListScreen extends StatefulWidget {
  const WaitingListScreen({super.key});
  @override
  State<WaitingListScreen> createState() => _WaitingListScreenState();
}

class _WaitingListScreenState extends State<WaitingListScreen>
    with TickerProviderStateMixin {
  bool _inQueue = false;
  int _position = 0;
  int _totalWaiting = 0;
  int _availableCount = 0;
  bool _loading = true;
  bool _actionLoading = false;

  // Offer state
  String? _status;         // 'waiting' or 'offered'
  String? _offeredSpotId;
  DateTime? _offerExpiresAt;

  // Countdown timer
  Timer? _pollTimer;
  Timer? _countdownTimer;
  int _secondsLeft = 300;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _checkStatus();
    // Poll every 8 seconds to detect spot offers in real time
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) => _checkStatus());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    try {
      final data = await ApiService.get(ApiConstants.myQueue);
      final spotsData = await ApiService.get(ApiConstants.spots);

      final newStatus = data['status'] as String?;
      final newOfferSpot = data['offeredSpotId'] as String?;
      final rawExpiry = data['offerExpiresAt'] as String?;
      final expiresAt = rawExpiry != null ? DateTime.tryParse(rawExpiry) : null;

      // If we just got a new offer, show a popup alert
      if (newStatus == 'offered' && _status != 'offered' && mounted) {
        _startCountdown(expiresAt);
        WidgetsBinding.instance.addPostFrameCallback((_) => _showOfferAlert(newOfferSpot));
      } else if (newStatus == 'offered' && expiresAt != null && _offerExpiresAt == null) {
        _startCountdown(expiresAt);
      }

      if (mounted) {
        setState(() {
          _inQueue = data['inQueue'] ?? false;
          _position = data['position'] ?? 0;
          _totalWaiting = data['totalWaiting'] ?? 0;
          _availableCount = spotsData['availableCount'] ?? 0;
          _status = newStatus;
          _offeredSpotId = newOfferSpot;
          _offerExpiresAt = expiresAt;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startCountdown(DateTime? expiresAt) {
    _countdownTimer?.cancel();
    if (expiresAt == null) return;
    setState(() {
      _secondsLeft = expiresAt.difference(DateTime.now()).inSeconds.clamp(0, 300);
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      final secs = expiresAt.difference(DateTime.now()).inSeconds;
      setState(() => _secondsLeft = secs.clamp(0, 300));
      if (secs <= 0) { t.cancel(); _checkStatus(); }
    });
  }

  void _showOfferAlert(String? spotId) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.local_parking, color: AppColors.primary, size: 28),
          SizedBox(width: 10),
          Text('Spot Available!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.available.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.available),
            ),
            child: Text(
              'Spot ${spotId ?? '?'} has been reserved for you!\nYou have 5 minutes to accept or decline.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.foreground),
            ),
          ),
          const SizedBox(height: 16),
          const Text('If you decline, the next person in queue will be offered this spot.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 13)),
        ]),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); _declineSpot(); },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Decline'),
          ),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _showAcceptDurationDialog(); },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }
  void _showAcceptDurationDialog() {
    int selectedDuration = 2;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Choose Duration', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How long do you need the spot?', style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: selectedDuration > 1
                        ? () => setS(() => selectedDuration--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                    iconSize: 32,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('$selectedDuration hr${selectedDuration > 1 ? "s" : ""}',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                  IconButton(
                    onPressed: selectedDuration < 24
                        ? () => setS(() => selectedDuration++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                    iconSize: 32,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: selectedDuration.toDouble(),
                min: 1,
                max: 24,
                divisions: 23,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.border,
                label: '$selectedDuration Hours',
                onChanged: (val) {
                  setS(() {
                    selectedDuration = val.round();
                  });
                },
              ),
              const SizedBox(height: 12),
              Text(
                selectedDuration == 1
                    ? 'Cost: FREE (first hour)'
                    : 'Cost: ${(selectedDuration - 1) * 10} EGP',
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _acceptSpot(selectedDuration);
              },
              child: const Text('Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _joinQueue() async {
    setState(() => _actionLoading = true);
    try {
      await ApiService.post(ApiConstants.joinQueue, {});
      await _checkStatus();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _acceptSpot(int duration) async {
    setState(() => _actionLoading = true);
    try {
      await ApiService.post(ApiConstants.acceptQueue, {'duration': duration});
      _countdownTimer?.cancel();
      await _checkStatus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✅ Spot booked successfully! Check My Bookings.'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 4),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _declineSpot() async {
    setState(() => _actionLoading = true);
    try {
      await ApiService.post(ApiConstants.declineQueue, {});
      _countdownTimer?.cancel();
      await _checkStatus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Spot declined. The next person in queue has been notified.'),
        backgroundColor: AppColors.muted,
      ));
    } catch (e) {
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _leaveQueue() async {
    setState(() => _actionLoading = true);
    try {
      await ApiService.delete(ApiConstants.leaveQueue);
      _countdownTimer?.cancel();
      setState(() { _inQueue = false; _position = 0; _status = null; _offeredSpotId = null; });
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        Container(
          color: AppColors.primary,
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 26)),
            const SizedBox(width: 16),
            const Text('Waiting List',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _checkStatus,
            ),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _actionLoading
                  ? const Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text('Processing...', style: TextStyle(color: AppColors.muted)),
                      ]))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: _buildContent(),
                    ),
        ),
      ]),
    );
  }

  Widget _buildContent() {
    // Show "spots available" banner when not in queue and garage has free spots
    if (!_inQueue && _availableCount > 0) {
      return _buildSpotsAvailableBanner();
    }
    if (!_inQueue) return _buildNotInQueue();
    if (_status == 'offered') return _buildOfferReceived();
    return _buildInQueue();
  }

  /// Banner shown when user tries to access waiting list but spots exist
  Widget _buildSpotsAvailableBanner() {
    return Column(children: [
      const SizedBox(height: 40),
      Container(
        width: 96, height: 96,
        decoration: BoxDecoration(
            color: AppColors.available.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: const Icon(Icons.check_circle_outline, size: 52, color: AppColors.available),
      ),
      const SizedBox(height: 20),
      const Text('Spots Are Available! 🎉',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.foreground)),
      const SizedBox(height: 8),
      const Text('No need to join the waiting list.',
          style: TextStyle(color: AppColors.muted, fontSize: 15)),
      const SizedBox(height: 24),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.available.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.available.withValues(alpha: 0.4)),
        ),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.available,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                '$_availableCount Spot${_availableCount > 1 ? 's' : ''} Free',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          const Text('Head to the Parking Map to book an available spot right now!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 14)),
        ]),
      ),
      const SizedBox(height: 28),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.pushReplacementNamed(context, '/map'),
          icon: const Icon(Icons.map_outlined),
          label: const Text('Go to Parking Map'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.available),
        ),
      ),
    ]);
  }

  /// When garage is fully occupied and user is not in queue
  Widget _buildNotInQueue() {
    return Column(children: [
      const SizedBox(height: 40),
      Container(
        width: 96, height: 96,
        decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: const Icon(Icons.people_outline, size: 52, color: AppColors.warning),
      ),
      const SizedBox(height: 20),
      const Text('Garage is Full',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.foreground)),
      const SizedBox(height: 8),
      const Text(
          'All parking spots are occupied.\nJoin the waiting list — you\'ll be automatically notified and offered a spot the moment one becomes free.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 14)),
      const SizedBox(height: 32),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('How It Works',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.foreground)),
          const SizedBox(height: 16),
          _step('1', 'Join the queue', 'Your position is saved. First in, first served.'),
          const SizedBox(height: 12),
          _step('2', 'Auto-offer when a spot frees up',
              'The system immediately offers you the spot'),
          const SizedBox(height: 12),
          _step('3', 'Accept or decline within 5 min',
              'Accept to book instantly. Decline passes it to the next person.'),
        ]),
      ),
      const SizedBox(height: 24),
      SizedBox(
          width: double.infinity,
          child: ElevatedButton(onPressed: _joinQueue, child: const Text('Join Waiting List'))),
    ]);
  }

  /// When user is in queue and waiting
  Widget _buildInQueue() {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.secondary.withValues(alpha: 0.1)
          ]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Container(
            width: 64, height: 64,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.people, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 16),
          const Text("You're in the Queue!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.foreground)),
          const SizedBox(height: 8),
          const Text("You'll be automatically notified when a spot opens up.",
              textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              const Text('Your position', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 4),
              Text('$_position',
                  style: const TextStyle(
                      fontSize: 52, fontWeight: FontWeight.w700, color: AppColors.primary)),
              Text('of $_totalWaiting in queue',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDE68A))),
        child: const Text(
            'When a spot becomes available, you\'ll get an in-app notification to accept or decline. '
            'You\'ll have 5 minutes to respond before it passes to the next person.',
            style: TextStyle(fontSize: 13, color: Color(0xFF92400E))),
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _leaveQueue,
          style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error)),
          child: const Text('Leave Queue'),
        ),
      ),
    ]);
  }

  /// When a spot has been actively offered to this user
  Widget _buildOfferReceived() {
    final mins = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final secs = (_secondsLeft % 60).toString().padLeft(2, '0');
    final isUrgent = _secondsLeft < 60;

    return Column(children: [
      ScaleTransition(
        scale: _pulseAnim,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.available.withValues(alpha: 0.15), AppColors.primary.withValues(alpha: 0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.available, width: 2),
            boxShadow: [BoxShadow(
                color: AppColors.available.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(children: [
            Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(color: AppColors.available, shape: BoxShape.circle),
              child: const Icon(Icons.local_parking, color: Colors.white, size: 46),
            ),
            const SizedBox(height: 16),
            const Text('🎉 A Spot is Yours!',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.foreground)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30)),
              child: Text(
                'Spot ${_offeredSpotId ?? '?'} is reserved for you',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 20),
            // Countdown timer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: isUrgent ? AppColors.error.withValues(alpha: 0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: isUrgent ? AppColors.error : AppColors.border)),
              child: Column(children: [
                Text('Time Remaining',
                    style: TextStyle(
                        fontSize: 12,
                        color: isUrgent ? AppColors.error : AppColors.muted)),
                const SizedBox(height: 4),
                Text('$mins:$secs',
                    style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: isUrgent ? AppColors.error : AppColors.primary,
                        fontFeatures: const [FontFeature.tabularFigures()])),
                Text(isUrgent ? 'Hurry up!' : 'before the offer expires',
                    style: TextStyle(
                        fontSize: 12,
                        color: isUrgent ? AppColors.error : AppColors.muted)),
              ]),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 20),
      const Text(
          'If you decline or the timer expires, the spot will automatically be offered to the next person in queue.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 13)),
      const SizedBox(height: 28),
      // Accept button
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _showAcceptDurationDialog,
          icon: const Icon(Icons.check_circle_outline, size: 22),
          label: const Text('Accept & Book Spot', style: TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.available,
            padding: const EdgeInsets.symmetric(vertical: 18),
            minimumSize: const Size(0, 0),
          ),
        ),
      ),
      const SizedBox(height: 12),
      // Decline button
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _declineSpot,
          icon: const Icon(Icons.close, size: 20),
          label: const Text('Decline — Pass to Next Person', style: TextStyle(fontSize: 14)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(0, 0),
          ),
        ),
      ),
    ]);
  }

  Widget _step(String num, String title, String desc) {
    return Row(children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Center(
            child: Text(num,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 12))),
      ),
      const SizedBox(width: 12),
      Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.foreground)),
        Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ])),
    ]);
  }
}
