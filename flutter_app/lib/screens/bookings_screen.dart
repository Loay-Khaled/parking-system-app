import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
import '../services/api_constants.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});
  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  List<Booking> _bookings = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadBookings(); }

  Future<void> _loadBookings() async {
    try {
      final data = await ApiService.get(ApiConstants.myBookings);
      setState(() {
        _bookings = (data as List).map((b) => Booking.fromJson(b)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _onNavTap(int index) {
    final routes = ['/home', '/map', '/bookings', '/profile'];
    if (index != 2) Navigator.pushReplacementNamed(context, routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final active = _bookings.where((b) => b.isActive).toList();
    final past = _bookings.where((b) => !b.isActive).toList();

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadBookings,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      color: AppColors.primary,
                      padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                      child: const Text('My Bookings', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  if (_loading)
                    const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                  else if (_bookings.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.calendar_today_outlined, size: 64, color: AppColors.muted),
                          const SizedBox(height: 16),
                          const Text('No bookings yet', style: TextStyle(fontSize: 18, color: AppColors.muted, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          const Text('Book a parking spot to get started', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, '/map'),
                            child: const Text('Find a Spot'),
                          ),
                        ]),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          if (active.isNotEmpty) ...[
                            const Text('Active Bookings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.foreground)),
                            const SizedBox(height: 12),
                            ...active.map((b) => _BookingCard(booking: b, onRefresh: _loadBookings)),
                            const SizedBox(height: 20),
                          ],
                          if (past.isNotEmpty) ...[
                            const Text('Past Bookings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.foreground)),
                            const SizedBox(height: 12),
                            ...past.map((b) => _BookingCard(booking: b, onRefresh: _loadBookings)),
                          ],
                        ]),
                      ),
                    ),
                ],
              ),
            ),
          ),
          BottomNav(currentIndex: 2, onTap: _onNavTap),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onRefresh;
  const _BookingCard({required this.booking, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: booking.isActive ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: booking.isActive ? AppColors.primary.withValues(alpha: 0.1) : AppColors.muted.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.location_on, color: booking.isActive ? AppColors.primary : AppColors.muted, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(booking.spotId, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.foreground)),
                Text('Zone ${booking.zone}', style: const TextStyle(fontSize: 13, color: AppColors.muted)),
              ])),
              if (booking.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Active', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          _infoRow(Icons.access_time, booking.timeRange),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total', style: TextStyle(fontSize: 13, color: AppColors.muted)),
            Text(booking.costDisplay, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.foreground)),
          ]),
          if (booking.isActive) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _cancel(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: const BorderSide(color: AppColors.error),
                  foregroundColor: AppColors.error,
                ),
                child: const Text('Cancel Booking'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.muted),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
    ]);
  }

  Future<void> _cancel(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.patch(ApiConstants.cancelBooking(booking.id));
      onRefresh();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
