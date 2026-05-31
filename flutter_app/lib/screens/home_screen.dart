import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/parking_spot.dart';
import '../services/api_service.dart';
import '../services/api_constants.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  User? _user;
  int _availableSpots = 0;
  int _totalSpots = 0;
  final int _currentNav = 0;
  bool _loading = true;

  // Nearest spot state
  ParkingSpot? _nearestSpot;
  bool _loadingNearest = true;
  bool _noSpotsAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _user = await AuthService.getUser();
    // Load spots count and nearest spot concurrently
    await Future.wait([
      _loadSpotsCount(),
      _loadNearestSpot(),
      _refreshUser(),
    ]);
  }

  Future<void> _loadSpotsCount() async {
    try {
      final spotsData = await ApiService.get(ApiConstants.spots);
      if (mounted) {
        setState(() {
          _availableSpots = spotsData['availableCount'] ?? 0;
          _totalSpots = spotsData['totalCount'] ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _refreshUser() async {
    try {
      final freshUser = await AuthService.refreshUser();
      if (mounted) setState(() { _user = freshUser; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadNearestSpot() async {
    if (mounted) setState(() { _loadingNearest = true; _noSpotsAvailable = false; });
    try {
      // Always fetch fresh from API — never use a cached value
      final spot = await ApiService.getNearestSpot(0.0, 0.0);
      if (mounted) {
        setState(() {
          _nearestSpot = spot;
          _noSpotsAvailable = spot == null;
          _loadingNearest = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _nearestSpot = null; _noSpotsAvailable = true; _loadingNearest = false; });
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([_loadSpotsCount(), _loadNearestSpot(), _refreshUser()]);
  }

  Future<void> _onBookNow() async {
    if (_nearestSpot == null) return;
    final spotId = _nearestSpot!.spotId;

    // Re-fetch spot status guard before navigating
    try {
      final freshData = await ApiService.get(ApiConstants.spotById(spotId));
      final freshSpot = ParkingSpot.fromJson(freshData);
      if (!freshSpot.isAvailable) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This spot was just taken. Finding next nearest spot…'),
            backgroundColor: Colors.orange,
          ),
        );
        await _loadNearestSpot();
        return;
      }
    } catch (_) {
      // If re-fetch fails, let the booking screen handle it
    }

    if (!mounted) return;
    Navigator.pushNamed(context, '/spot-details', arguments: spotId);
  }

  void _onNavTap(int index) {
    final routes = ['/home', '/map', '/bookings', '/profile'];
    if (index != _currentNav) {
      Navigator.pushReplacementNamed(context, routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildNearestSpotCard(),
                          const SizedBox(height: 16),
                          _buildSummaryCard(),
                          const SizedBox(height: 16),
                          _buildAvailabilityCard(),
                          const SizedBox(height: 16),
                          _buildPromoCard(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            BottomNav(currentIndex: _currentNav, onTap: _onNavTap),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: const Icon(Icons.local_parking, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Welcome back,', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text(_user?.name ?? 'User', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/notifications'),
                child: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Available Spots', style: TextStyle(fontSize: 13, color: AppColors.muted)),
                    _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('$_availableSpots',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.success)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _totalSpots > 0 ? _availableSpots / _totalSpots : 0,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text('$_availableSpots of $_totalSpots spots available',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearestSpotCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: _loadingNearest
          ? _buildNearestSpotShimmer()
          : _noSpotsAvailable || _nearestSpot == null
              ? _buildNoSpotsState()
              : _buildNearestSpotContent(),
    );
  }

  Widget _buildNearestSpotShimmer() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: 100, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 6),
                  Container(height: 12, width: 80, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
            Container(height: 28, width: 80, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(30))),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          height: 44, width: double.infinity,
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
        ),
      ],
    );
  }

  Widget _buildNoSpotsState() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.location_off, color: Colors.grey, size: 26),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No spots available right now', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.foreground)),
                  Text('Check back in a few minutes', style: TextStyle(fontSize: 13, color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNearestSpotContent() {
    final spot = _nearestSpot!;
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.location_on, color: AppColors.success, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nearest Spot', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.foreground)),
                  Text('Zone ${spot.zone} – ${spot.spotId}', style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30)),
              child: const Text('Available', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _onBookNow,
            child: const Text('Book Now'),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.access_time, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('Quick Summary', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.foreground)),
            ],
          ),
          const SizedBox(height: 16),
          _summaryRow('Total Bookings', '${_user?.totalBookings ?? 0}', AppColors.foreground),
          const SizedBox(height: 12),
          _summaryRow('Total Spent', '${_user?.totalSpent.toInt() ?? 0} EGP', AppColors.foreground),
          const SizedBox(height: 12),
          _summaryRow('Penalties', '${_user?.activePenalties.toInt() ?? 0} EGP', AppColors.error),
        ],
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('Typical Parking Patterns', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.foreground)),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Check the predicted busyness of parking zones A, B, and C based on historical data.',
              style: TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/predicted-availability'),
              child: const Text('View Predicted Availability'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor)),
      ],
    );
  }

  Widget _buildPromoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.secondary.withValues(alpha: 0.1), AppColors.primary.withValues(alpha: 0.1)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.directions_car, color: AppColors.secondary, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('First Hour Free!', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.foreground)),
                SizedBox(height: 4),
                Text('Book any spot and enjoy your first hour free. Additional hours only 10 EGP.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
