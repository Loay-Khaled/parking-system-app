import 'package:flutter/material.dart';
import '../models/parking_spot.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/api_constants.dart';
import '../services/recommendation_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<ParkingSpot> _spots = [];
  bool _loading = true;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  ParkingSpot? _nearestSpot;
  bool _loadingNearest = false;

  List<ParkingSpot> _recommendedSpots = [];
  String _recommendationMessage = '';
  bool _loadingRecommendations = true;

  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadSpots();
    _loadRecommendations();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    setState(() => _currentUser = user);
  }

  Future<void> _loadRecommendations() async {
    try {
      final res = await RecommendationService.fetchRecommendations();
      setState(() {
        _recommendedSpots = res['recommendedSpots'] as List<ParkingSpot>;
        _recommendationMessage = res['message'] as String;
        _loadingRecommendations = false;
      });
    } catch (_) {
      setState(() => _loadingRecommendations = false);
    }
  }

  Future<void> _findNearestSpot() async {
    setState(() => _loadingNearest = true);
    try {
      final spot = await ApiService.getNearestSpot(0.0, 0.0);

      if (spot != null &&
          spot.isAccessibility == true &&
          _currentUser?.accessibilityPermit.status != 'approved') {
        setState(() {
          _nearestSpot = null;
          _loadingNearest = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No regular spots available right now.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      setState(() {
        _nearestSpot = spot;
        _loadingNearest = false;
      });
      if (spot != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recommended Spot: ${spot.spotId} (Zone ${spot.zone})'),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Book Now',
              textColor: Colors.amberAccent,
              onPressed: () {
                Navigator.pushNamed(context, '/spot-details', arguments: spot.spotId);
              },
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No available parking spots found.'), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      setState(() => _loadingNearest = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _loadSpots() async {
    try {
      final data = await ApiService.get(ApiConstants.spots);
      setState(() {
        _spots = (data['spots'] as List).map((s) => ParkingSpot.fromJson(s)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  List<ParkingSpot> _filteredByZone(String zone) {
    return _spots.where((s) {
      final matchesZone = s.zone == zone;
      final matchesSearch = _searchQuery.isEmpty || s.spotId.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesZone && matchesSearch;
    }).toList();
  }

  Color _spotColor(String status) {
    switch (status) {
      case 'available': return AppColors.available;
      case 'occupied': return AppColors.occupied;
      case 'reserved': return AppColors.reserved;
      default: return AppColors.muted;
    }
  }

  void _onNavTap(int index) {
    final routes = ['/home', '/map', '/bookings', '/profile'];
    if (index != 1) Navigator.pushReplacementNamed(context, routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('MediaQuery padding bottom: ${MediaQuery.of(context).padding.bottom}');
    debugPrint('MediaQuery viewInsets bottom: ${MediaQuery.of(context).viewInsets.bottom}');
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadSpots,
                  child: CustomScrollView(
                    clipBehavior: Clip.none,
                    slivers: [
                      SliverToBoxAdapter(child: _buildHeader()),
                      if (_loading)
                        const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                      else
                        SliverPadding(
                          padding: EdgeInsets.only(
                            left: 20,
                            right: 20,
                            top: 20,
                            bottom: 100 + MediaQuery.of(context).padding.bottom,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              _buildRecommendationsSection(),
                              _buildLegend(),
                              const SizedBox(height: 20),
                              for (final zone in ['A', 'B', 'C']) ...[
                                _buildZoneSection(zone),
                                const SizedBox(height: 20),
                              ],
                              SizedBox(height: 120 + MediaQuery.of(context).padding.bottom),
                            ]),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              BottomNav(currentIndex: 1, onTap: _onNavTap),
            ],
          ),
          Positioned(
            bottom: kBottomNavigationBarHeight + 16 + MediaQuery.of(context).padding.bottom,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: _loadingNearest ? null : _findNearestSpot,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: _loadingNearest
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.near_me),
              label: const Text('Find Nearest Spot', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Parking Map', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Search spot or zone...',
              prefixIcon: const Icon(Icons.search, color: AppColors.muted),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _legendItem(AppColors.available, 'Available'),
        _legendItem(AppColors.occupied, 'Occupied'),
        _legendItem(AppColors.reserved, 'Reserved'),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: const Center(
                child: Icon(Icons.accessible, size: 10, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 6),
            const Text('Disabled', style: TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(children: [
      Container(width: 16, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
    ]);
  }

  Widget _buildZoneSection(String zone) {
    final zoneSpots = _filteredByZone(zone);
    if (zoneSpots.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.location_on, color: AppColors.primary, size: 18),
          const SizedBox(width: 6),
          Text('Zone $zone', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.foreground)),
        ]),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.1,
          ),
          itemCount: zoneSpots.length,
          itemBuilder: (_, i) => _buildSpotCard(zoneSpots[i]),
        ),
      ],
    );
  }

  void _showAccessibilityWarningSheet(ParkingSpot spot) {
    final status = _currentUser?.accessibilityPermit.status ?? 'none';
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String statusText = 'Not Applied';
        String actionButtonText = 'Apply for Permit';
        IconData statusIcon = Icons.info_outline;
        Color statusColor = AppColors.muted;

        if (status == 'pending') {
          statusText = 'Pending Review';
          actionButtonText = 'Check Status';
          statusIcon = Icons.pending_actions;
          statusColor = AppColors.warning;
        } else if (status == 'rejected') {
          statusText = 'Application Rejected';
          actionButtonText = 'Re-apply for Permit';
          statusIcon = Icons.cancel_outlined;
          statusColor = AppColors.error;
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.accessible, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spot ${spot.spotId}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.foreground),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          spot.accessibilityLabel.isNotEmpty ? spot.accessibilityLabel : 'Reserved Accessibility Spot',
                          style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                status == 'pending'
                    ? 'Your application for an accessibility permit is currently pending review by our administration team. You cannot book this spot until your application is approved.'
                    : status == 'rejected'
                        ? 'Your application for an accessibility permit was rejected. Please review the details on your profile and submit a new application to book this spot.'
                        : 'Only users with an approved accessibility permit are authorized to book this spot. Booking is restricted to ensure parking availability for disabled users.',
                style: const TextStyle(color: AppColors.muted, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 20),
                    const SizedBox(width: 10),
                    const Text(
                      'Your Permit Status: ',
                      style: TextStyle(fontSize: 13, color: AppColors.foreground, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      statusText.toUpperCase(),
                      style: TextStyle(fontSize: 13, color: statusColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, '/accessibility-permit').then((_) {
                      _loadUser();
                    });
                  },
                  child: Text(actionButtonText),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpotCard(ParkingSpot spot) {
    final color = _spotColor(spot.status);
    final canTap = spot.status != 'occupied';
    final isNearest = _nearestSpot != null && spot.spotId == _nearestSpot!.spotId;
    
    final isAcc = spot.isAccessibility;
    final isAccAvailable = isAcc && spot.status == 'available';

    final fillBg = isNearest
        ? AppColors.primaryDark
        : (isAccAvailable ? AppColors.primary.withValues(alpha: 0.3) : color);

    final borderColor = isNearest
        ? Colors.amber
        : (isAcc ? AppColors.primary : color.withValues(alpha: 0.3));

    final borderThickness = isNearest
        ? 3.5
        : (isAcc ? 4.0 : 2.0);

    final textColor = isNearest
        ? Colors.amberAccent
        : (isAccAvailable ? AppColors.primary : Colors.white);

    return GestureDetector(
      onTap: canTap ? () {
        if (isAcc && _currentUser?.accessibilityPermit.status != 'approved') {
          _showAccessibilityWarningSheet(spot);
        } else {
          Navigator.pushNamed(context, '/spot-details', arguments: spot.spotId);
        }
      } : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: fillBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: borderThickness,
          ),
          boxShadow: isNearest
              ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.6), blurRadius: 12, spreadRadius: 2)]
              : (canTap ? [BoxShadow(color: (isAcc ? AppColors.primary : color).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))] : null),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAcc) ...[
                  Icon(
                    Icons.accessible,
                    size: 18,
                    color: textColor,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  spot.spotId,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: textColor,
                  ),
                ),
              ],
            ),
            if (isNearest)
              const Text('NEAREST', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
            if (!isNearest && spot.isReserved && spot.availableAt != null)
              Text(
                spot.availableAt!,
                style: TextStyle(
                  fontSize: 10,
                  color: isAccAvailable ? AppColors.primary.withValues(alpha: 0.8) : Colors.white70,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    if (_loadingRecommendations) {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 140,
              height: 16,
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(2, (i) => Container(
                width: 120,
                height: 70,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              )),
            ),
          ],
        ),
      );
    }

    if (_recommendedSpots.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '★ Recommended for you',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.foreground),
            ),
            if (_recommendationMessage.isNotEmpty)
              Text(
                _recommendationMessage,
                style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 86,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recommendedSpots.length,
            itemBuilder: (context, idx) {
              final spot = _recommendedSpots[idx];
              Color zoneColor = Colors.blue;
              if (spot.zone == 'B') zoneColor = Colors.green;
              if (spot.zone == 'C') zoneColor = Colors.orange;

              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/spot-details', arguments: spot.spotId);
                },
                child: Container(
                  width: 130,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(spot.spotId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.foreground)),
                          if (spot.previouslyUsed)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                              child: const Text('USED', style: TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Floor ${spot.floor}', style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: zoneColor, shape: BoxShape.circle),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
