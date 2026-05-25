import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/api_constants.dart';
import 'admin_bottom_nav.dart';

class AdminSpotsScreen extends StatefulWidget {
  const AdminSpotsScreen({super.key});

  @override
  State<AdminSpotsScreen> createState() => _AdminSpotsScreenState();
}

class _AdminSpotsScreenState extends State<AdminSpotsScreen> {
  static const _primary = Color(0xFF1E3A5F);

  List<dynamic> _spots = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSpots();
  }

  Future<void> _loadSpots() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.get(ApiConstants.adminSpots);
      setState(() {
        _spots = data is List ? data : [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Color _spotColor(String status) {
    switch (status) {
      case 'available':
        return const Color(0xFF10B981);
      case 'occupied':
        return const Color(0xFFEF4444);
      case 'reserved':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  void _openStatusSheet(Map<String, dynamic> spot) {
    String selected = spot['status']?.toString() ?? 'available';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      spot['spotId']?.toString() ?? '—',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Zone ${spot['zone'] ?? '—'} • Floor ${spot['floor'] ?? 1}',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Override Status',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 12),
              ...['available', 'occupied', 'reserved'].map((s) {
                final color = _spotColor(s);
                final isSelected = selected == s;
                return GestureDetector(
                  onTap: () => setSheet(() => selected = s),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          s[0].toUpperCase() + s.substring(1),
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                            color: isSelected ? color : const Color(0xFF1A1F36),
                          ),
                        ),
                        const Spacer(),
                        if (isSelected) Icon(Icons.check_circle, color: color, size: 18),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _updateStatus(
                      spot['spotId']?.toString() ?? '',
                      selected,
                    );
                  },
                  child: const Text('Apply Status', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateStatus(String spotId, String status) async {
    try {
      await ApiService.patch(ApiConstants.adminUpdateSpotStatus(spotId), {'status': status});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$spotId → $status'),
          backgroundColor: Colors.green,
        ),
      );
      _loadSpots();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: _primary,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Parking Spots',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            Text(
              '${_spots.length} spots total',
              style: const TextStyle(fontSize: 11, color: Colors.white60),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadSpots,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A5F)))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadSpots,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _legend(),
                        const SizedBox(height: 16),
                        ...['A', 'B', 'C'].map((zone) => _zoneSection(zone)),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 3),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            Text(
              _error!.replaceAll('Exception: ', ''),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: _primary),
              onPressed: _loadSpots,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem('Available', const Color(0xFF10B981)),
        const SizedBox(width: 20),
        _legendItem('Occupied', const Color(0xFFEF4444)),
        const SizedBox(width: 20),
        _legendItem('Reserved', const Color(0xFFF59E0B)),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _zoneSection(String zone) {
    final zoneSpots = _spots
        .where((s) => (s as Map<String, dynamic>)['zone'] == zone)
        .cast<Map<String, dynamic>>()
        .toList();

    if (zoneSpots.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Zone $zone',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.25,
          ),
          itemCount: zoneSpots.length,
          itemBuilder: (ctx, i) => _spotTile(zoneSpots[i]),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _spotTile(Map<String, dynamic> spot) {
    final status = spot['status']?.toString() ?? 'available';
    final color = _spotColor(status);
    return GestureDetector(
      onTap: () => _openStatusSheet(spot),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_parking, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              spot['spotId']?.toString() ?? '—',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: color,
                fontSize: 13,
              ),
            ),
            Text(
              status,
              style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }
}
