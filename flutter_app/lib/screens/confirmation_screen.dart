import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/booking.dart';
import '../theme/app_theme.dart';

class ConfirmationScreen extends StatelessWidget {
  final Booking booking;
  const ConfirmationScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              _buildSuccessHeader(),
              const SizedBox(height: 24),
              _buildDetailsCard(),
              const SizedBox(height: 16),
              _buildQRCard(),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false),
                  child: const Text('Back to Home'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/bookings', (r) => false),
                  child: const Text('View My Bookings'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return Column(
      children: [
        Container(
          width: 80, height: 80,
          decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
          child: const Icon(Icons.check, color: Colors.white, size: 44),
        ),
        const SizedBox(height: 16),
        const Text('Booking Confirmed!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.foreground)),
        const SizedBox(height: 8),
        const Text('Your parking spot has been reserved successfully',
            textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 14)),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          _detailRow(Icons.location_on, 'Parking Spot', 'Zone ${booking.zone} - Spot ${booking.spotId}'),
          const Divider(height: 24, color: AppColors.border),
          _detailRow(Icons.access_time, 'Duration', '${booking.duration} Hour${booking.duration > 1 ? 's' : ''} (${booking.timeRange})'),
          const Divider(height: 24, color: AppColors.border),
          _detailRow(Icons.receipt, 'Total Cost', booking.costDisplay, valueColor: AppColors.success),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.foreground)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQRCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.qr_code_2, color: AppColors.muted),
            SizedBox(width: 8),
            Text('Entry QR Code', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.foreground)),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.05), AppColors.secondary.withValues(alpha: 0.05)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: booking.qrCode ?? 'AAST-${booking.spotId}-${booking.id}',
              version: QrVersions.auto,
              size: 180,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text('Show this QR code at the parking entrance',
              style: TextStyle(fontSize: 12, color: AppColors.muted), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
