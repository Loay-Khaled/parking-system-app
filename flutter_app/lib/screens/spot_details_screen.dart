import 'package:flutter/material.dart';
import '../models/parking_spot.dart';
import '../services/api_service.dart';
import '../services/api_constants.dart';
import '../theme/app_theme.dart';

class SpotDetailsScreen extends StatefulWidget {
  final String spotId;
  const SpotDetailsScreen({super.key, required this.spotId});
  @override
  State<SpotDetailsScreen> createState() => _SpotDetailsScreenState();
}

class _SpotDetailsScreenState extends State<SpotDetailsScreen> {
  ParkingSpot? _spot;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSpot();
  }

  Future<void> _loadSpot() async {
    try {
      final data = await ApiService.get(ApiConstants.spotById(widget.spotId));
      setState(() { _spot = ParkingSpot.fromJson(data); _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                const Text('Spot Details', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _spot == null
                    ? const Center(child: Text('Spot not found'))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildSpotHeader(),
                            const SizedBox(height: 16),
                            _buildPricingCard(),
                            const SizedBox(height: 16),
                            _buildNoticeCard(),
                            const SizedBox(height: 24),
                            if (_spot!.isAvailable)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pushNamed(context, '/booking', arguments: widget.spotId),
                                  child: const Text('Book This Spot'),
                                ),
                              ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotHeader() {
    final statusColor = _spot!.isAvailable ? AppColors.success : _spot!.isOccupied ? AppColors.error : AppColors.warning;
    final statusText = _spot!.isAvailable ? 'Available' : _spot!.isOccupied ? 'Occupied' : 'Reserved';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.location_on, color: AppColors.success, size: 36),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.spotId, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.foreground)),
                  Text('Zone ${_spot!.zone}', style: const TextStyle(fontSize: 14, color: AppColors.muted)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30)),
                child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.border),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.access_time, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Availability', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.foreground)),
              Text(_spot!.isAvailable ? 'Available now' : 'Currently unavailable',
                  style: const TextStyle(fontSize: 13, color: AppColors.muted)),
            ]),
          ]),
        ],
      ),
    );
  }

  Widget _buildPricingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.attach_money, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Pricing', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.foreground)),
          ]),
          const SizedBox(height: 16),
          _priceRow('First hour', 'FREE', AppColors.success),
          const Divider(height: 20, color: AppColors.border),
          _priceRow('Additional hours', '10 EGP/hour', AppColors.foreground),
          const Divider(height: 20, color: AppColors.border),
          _priceRow('Overstay penalty', '20 EGP/hour', AppColors.error),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor)),
      ],
    );
  }

  Widget _buildNoticeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Important Notice', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E40AF))),
          SizedBox(height: 8),
          Text('• Please arrive within 15 minutes of booking', style: TextStyle(fontSize: 13, color: Color(0xFF1D4ED8))),
          SizedBox(height: 4),
          Text('• Parking in another user\'s spot will incur penalties', style: TextStyle(fontSize: 13, color: Color(0xFF1D4ED8))),
          SizedBox(height: 4),
          Text('• Overstaying will be charged at double rate', style: TextStyle(fontSize: 13, color: Color(0xFF1D4ED8))),
        ],
      ),
    );
  }
}
