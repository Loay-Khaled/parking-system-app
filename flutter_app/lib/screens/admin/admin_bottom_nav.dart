import 'package:flutter/material.dart';

class AdminBottomNav extends StatelessWidget {
  final int currentIndex;

  const AdminBottomNav({super.key, required this.currentIndex});

  static const _routes = [
    '/admin-home',
    '/admin-users',
    '/admin-bookings',
    '/admin-spots',
    '/admin-notifications',
  ];

  static const _tabs = [
    {'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard, 'label': 'Dashboard'},
    {'icon': Icons.people_outline, 'activeIcon': Icons.people, 'label': 'Users'},
    {'icon': Icons.book_outlined, 'activeIcon': Icons.book, 'label': 'Bookings'},
    {'icon': Icons.local_parking, 'activeIcon': Icons.local_parking, 'label': 'Spots'},
    {'icon': Icons.notifications_outlined, 'activeIcon': Icons.notifications, 'label': 'Notify'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A5F),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_tabs.length, (i) {
              final isActive = currentIndex == i;
              final tab = _tabs[i];
              return GestureDetector(
                onTap: () {
                  if (currentIndex != i) {
                    Navigator.pushReplacementNamed(context, _routes[i]);
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive
                            ? tab['activeIcon'] as IconData
                            : tab['icon'] as IconData,
                        color: isActive ? Colors.white : Colors.white38,
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tab['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                          color: isActive ? Colors.white : Colors.white38,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isActive ? 16 : 0,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
