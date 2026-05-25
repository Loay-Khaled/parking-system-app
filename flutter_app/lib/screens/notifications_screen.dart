import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/api_service.dart';
import '../services/api_constants.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await ApiService.get(ApiConstants.notifications);
      setState(() {
        _notifications = (data as List).map((n) => AppNotification.fromJson(n)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ApiService.patch(ApiConstants.readAllNotifications);
      _load();
    } catch (e) {
      // ignore
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'success': return AppColors.success;
      case 'warning': return AppColors.warning;
      case 'error': return AppColors.error;
      default: return AppColors.primary;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'success': return Icons.check_circle_outline;
      case 'warning': return Icons.access_time;
      case 'error': return Icons.cancel_outlined;
      default: return Icons.info_outline;
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
                GestureDetector(onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 26)),
                const SizedBox(width: 16),
                const Expanded(child: Text('Notifications',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700))),
                if (_notifications.any((n) => !n.read))
                  TextButton(
                    onPressed: _markAllRead,
                    child: const Text('Mark all read', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _notifications.isEmpty
                    ? const Center(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.notifications_none, size: 64, color: AppColors.muted),
                          SizedBox(height: 16),
                          Text('No notifications yet', style: TextStyle(color: AppColors.muted, fontSize: 16)),
                        ]),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: _notifications.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final n = _notifications[i];
                            final color = _typeColor(n.type);
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: n.read ? Colors.white : AppColors.primary.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: n.read ? AppColors.border : AppColors.primary.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42, height: 42,
                                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                    child: Icon(_typeIcon(n.type), color: color, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Row(children: [
                                        Expanded(child: Text(n.title,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.foreground))),
                                        if (!n.read) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                                      ]),
                                      const SizedBox(height: 4),
                                      Text(n.message, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                                      const SizedBox(height: 4),
                                      Text(n.timeAgo, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                                    ]),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
