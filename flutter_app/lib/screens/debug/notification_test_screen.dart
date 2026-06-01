import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  bool _runningAll = false;
  int _currentTestIndex = -1;

  final List<Map<String, String>> _tests = [
    {
      'id': 'N1',
      'title': 'Test N1 — Expiry Warning',
      'desc': 'Booking expiry warning (15 min before endTime)',
      'notiTitle': 'Parking Expiry Warning',
      'notiBody': 'Your booking for spot A2 expires in 15 minutes.',
      'channel': 'parking_reminders',
      'payload': 'expiry_warning:bookingId123',
    },
    {
      'id': 'N2',
      'title': 'Test N2 — Grace Period Cancelled',
      'desc': 'No-show grace period cancellation (booking auto-cancelled)',
      'notiTitle': 'Booking Cancelled',
      'notiBody': 'Your booking for spot A2 was cancelled due to no-show.',
      'channel': 'parking_alerts',
      'payload': 'grace_period_cancelled:bookingId123',
    },
    {
      'id': 'N3',
      'title': 'Test N3 — Waitlist Spot Available',
      'desc': 'Waiting list spot available (next user in queue notified)',
      'notiTitle': 'Parking Spot Available',
      'notiBody': 'Spot A2 is now available! Tap to book it.',
      'channel': 'parking_alerts',
      'payload': 'waitlist_available:spotId123',
    },
    {
      'id': 'N4',
      'title': 'Test N4 — Permit Granted',
      'desc': 'Accessibility permit granted (admin approved permit)',
      'notiTitle': 'Accessibility Permit Approved',
      'notiBody': 'Your accessibility permit request has been approved.',
      'channel': 'parking_alerts',
      'payload': 'permit_granted',
    },
    {
      'id': 'N5',
      'title': 'Test N5 — Permit Revoked',
      'desc': 'Accessibility permit revoked (admin revoked permit)',
      'notiTitle': 'Accessibility Permit Revoked',
      'notiBody': 'Your accessibility permit has been revoked.',
      'channel': 'parking_alerts',
      'payload': 'permit_revoked',
    },
    {
      'id': 'N6',
      'title': 'Test N6 — Booking Cancelled (Permit Revoked)',
      'desc': 'Active booking cancelled due to permit revocation',
      'notiTitle': 'Active Booking Cancelled',
      'notiBody': 'Your active booking was cancelled because your permit was revoked.',
      'channel': 'parking_alerts',
      'payload': 'permit_revocation_cancelled:bookingId123',
    },
    {
      'id': 'N7',
      'title': 'Test N7 — Appeal Approved',
      'desc': 'Appeal resolved — approved (penalty refunded)',
      'notiTitle': 'Appeal Approved',
      'notiBody': 'Your appeal has been approved and the penalty has been refunded.',
      'channel': 'parking_alerts',
      'payload': 'appeal_approved',
    },
    {
      'id': 'N8',
      'title': 'Test N8 — Appeal Rejected',
      'desc': 'Appeal resolved — rejected',
      'notiTitle': 'Appeal Rejected',
      'notiBody': 'Your appeal request was rejected.',
      'channel': 'parking_alerts',
      'payload': 'appeal_rejected',
    },
  ];

  Future<void> _fireNotification(Map<String, String> test, int id) async {
    final isReminder = test['channel'] == 'parking_reminders';
    final androidDetails = AndroidNotificationDetails(
      test['channel']!,
      isReminder ? 'Parking Reminders' : 'Parking Alerts',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    final details = NotificationDetails(android: androidDetails);

    await NotificationService.plugin.show(
      id,
      test['notiTitle']!,
      test['notiBody']!,
      details,
      payload: test['payload'],
    );
  }

  Future<void> _runAllTests() async {
    setState(() {
      _runningAll = true;
    });

    for (int i = 0; i < _tests.length; i++) {
      if (!mounted || !_runningAll) break;
      setState(() {
        _currentTestIndex = i;
      });
      await _fireNotification(_tests[i], i + 1);
      // Wait 5 seconds between each notification
      await Future.delayed(const Duration(seconds: 5));
    }

    if (mounted) {
      setState(() {
        _runningAll = false;
        _currentTestIndex = -1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All 8 notification tests fired successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Notifications'),
        actions: [
          if (_runningAll)
            IconButton(
              icon: const Icon(Icons.stop, color: Colors.white),
              onPressed: () {
                setState(() {
                  _runningAll = false;
                  _currentTestIndex = -1;
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (_runningAll)
            Container(
              color: AppColors.warning.withValues(alpha: 0.15),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.warning),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Firing notifications (5s interval)... Running N${_currentTestIndex + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.foreground),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _tests.length,
              itemBuilder: (context, index) {
                final test = _tests[index];
                final isCurrent = _runningAll && _currentTestIndex == index;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isCurrent ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrent ? AppColors.primary : AppColors.border,
                      width: isCurrent ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      test['title']!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.foreground),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(test['desc']!, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Payload: ${test['payload']}',
                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.muted),
                          ),
                        ),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: _runningAll ? null : () => _fireNotification(test, index + 1),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: const Size(60, 36),
                      ),
                      child: const Text('Fire', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _runningAll ? null : _runAllTests,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Test ALL (5s Interval)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
