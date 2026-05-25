import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;

  @override
  void initState() { super.initState(); _loadUser(); }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    setState(() => _user = user);
  }

  void _onNavTap(int index) {
    final routes = ['/home', '/map', '/bookings', '/profile'];
    if (index != 3) Navigator.pushReplacementNamed(context, routes[index]);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await AuthService.clearSession();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildVehicleCard(),
                        const SizedBox(height: 16),
                        _buildSummaryCard(),
                        const SizedBox(height: 16),
                        _buildMenuCard(),
                        const SizedBox(height: 16),
                        _buildLogoutButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          BottomNav(currentIndex: 3, onTap: _onNavTap),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profile', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                child: const Icon(Icons.person, size: 40, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_user?.name ?? 'Loading...', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(_user?.email ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vehicle Information', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.foreground)),
          const SizedBox(height: 16),
          Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.directions_car, color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Car Plate Number', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              Text(_user?.carPlate ?? '-', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.foreground)),
            ]),
          ]),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Account Summary', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.foreground)),
          const SizedBox(height: 16),
          _statRow('Total Bookings', '${_user?.totalBookings ?? 0}', AppColors.foreground),
          const Divider(height: 20, color: AppColors.border),
          _statRow('Active Penalties', '${_user?.activePenalties.toInt() ?? 0} EGP', AppColors.error),
          const Divider(height: 20, color: AppColors.border),
          _statRow('Total Spent', '${_user?.totalSpent.toInt() ?? 0} EGP', AppColors.foreground),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, Color valueColor) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor)),
    ]);
  }

  Widget _buildMenuCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          _menuItem(Icons.credit_card_outlined, 'Payment Methods', () {}),
          const Divider(height: 1, color: AppColors.border),
          _menuItem(Icons.notifications_outlined, 'Notifications', () => Navigator.pushNamed(context, '/notifications')),
          const Divider(height: 1, color: AppColors.border),
          _menuItem(Icons.access_time, 'Waiting List', () => Navigator.pushNamed(context, '/waiting-list')),
          const Divider(height: 1, color: AppColors.border),
          _menuItem(Icons.shield_outlined, 'Privacy & Security', () {}),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(children: [
          Icon(icon, color: AppColors.muted, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15, color: AppColors.foreground))),
          const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
        ]),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _logout,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.logout, color: AppColors.error, size: 20),
          SizedBox(width: 8),
          Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 15)),
        ]),
      ),
    );
  }
}
