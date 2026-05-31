import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
    FlutterLocalNotificationsPlugin();

  static Future<void> initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(settings);

    // Request POST_NOTIFICATIONS permission on Android 13+ (API 33+)
    await _notifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
  }

  static Future<void> showReminderNotification({
    required String bookingId,
    required String spotCode,
    required String endTime,
  }) async {
    const AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
        'parking_reminders',       // channel id
        'Parking Reminders',       // channel name
        channelDescription: 'Alerts before your parking session expires',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      bookingId.hashCode,          // unique notification id derived from bookingId
      '⏰ Parking Expiring Soon',
      'Your booking for spot $spotCode expires at $endTime. '
      'Move your car to avoid penalties.',
      details,
    );
  }
}
