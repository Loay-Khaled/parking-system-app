import 'package:flutter/material.dart';
import '../models/parking_spot.dart';
import '../services/api_service.dart';
import '../services/api_constants.dart';
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

  @override
  void initState() {
    super.initState();
    _loadSpots();
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
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadSpots,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  if (_loading)
                    const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildLegend(),
                          const SizedBox(height: 20),
                          for (final zone in ['A', 'B', 'C']) ...[
                            _buildZoneSection(zone),
                            const SizedBox(height: 20),
                          ],
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
    return Row(
      children: [
        _legendItem(AppColors.available, 'Available'),
        const SizedBox(width: 20),
        _legendItem(AppColors.occupied, 'Occupied'),
        const SizedBox(width: 20),
        _legendItem(AppColors.reserved, 'Reserved'),
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

  Widget _buildSpotCard(ParkingSpot spot) {
    final color = _spotColor(spot.status);
    final canTap = spot.status != 'occupied';
    return GestureDetector(
      onTap: canTap ? () => Navigator.pushNamed(context, '/spot-details', arguments: spot.spotId) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          boxShadow: canTap ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(spot.spotId, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white)),
            if (spot.isReserved && spot.availableAt != null)
              Text(spot.availableAt!, style: const TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
