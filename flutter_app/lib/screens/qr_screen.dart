import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
import '../services/api_constants.dart';
import '../theme/app_theme.dart';

class QrScreen extends StatefulWidget {
  final String bookingId;
  const QrScreen({super.key, required this.bookingId});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  Booking? _booking;
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadBooking();
    // Auto-update status when gate admin scans QR code
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _loadBooking(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadBooking({bool silent = false}) async {
    try {
      final response = await ApiService.get('${ApiConstants.baseUrl}/bookings/${widget.bookingId}');
      if (mounted) {
        setState(() {
          _booking = Booking.fromJson(response);
          _loading = false;
        });
      }
    } catch (_) {
      if (!silent && mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _statusBadge(Booking booking) {
    Color color = Colors.grey;
    String label = "Awaiting check-in";

    if (booking.noShowCancelled || booking.status == 'cancelled') {
      color = AppColors.error;
      label = booking.noShowCancelled ? "No-show / Cancelled" : "Cancelled";
    } else if (booking.isCheckedOut || booking.status == 'completed') {
      color = AppColors.primary;
      label = "Completed";
    } else if (booking.isCheckedIn) {
      color = AppColors.success;
      label = "Checked in";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qrData = _booking != null
        ? jsonEncode({
            'bookingId': _booking!.id,
            'qrCode': _booking!.qrCode,
          })
        : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gate Pass QR'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _booking == null
              ? const Center(child: Text('Error loading pass details.'))
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.qr_code_scanner, color: AppColors.primary),
                                  SizedBox(width: 8),
                                  Text(
                                    'AAST Smart Gate Pass',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.foreground),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: QrImageView(
                                  data: qrData,
                                  version: QrVersions.auto,
                                  size: 200,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _statusBadge(_booking!),
                              const SizedBox(height: 16),
                              const Divider(color: AppColors.border),
                              const SizedBox(height: 12),
                              _infoText('Parking Spot', 'Zone ${_booking!.zone} - Spot ${_booking!.spotId}'),
                              const SizedBox(height: 8),
                              _infoText('Time Window', _booking!.timeRange),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Scan this QR code at the entrance when entering, and at the exit when leaving.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _infoText(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.foreground)),
      ],
    );
  }
}
