import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  if (response.payload != null) {
    NotificationService.pendingNotificationPayload = response.payload;
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
    FlutterLocalNotificationsPlugin();

  static String? pendingNotificationPayload;

  static FlutterLocalNotificationsPlugin get plugin => _notifications;

  static Future<void> initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        handleNotificationPayload(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Create high importance channels on Android
    final androidPlugin = _notifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'parking_reminders',
          'Parking Reminders',
          description: 'Alerts before your parking session expires',
          importance: Importance.high,
          playSound: true,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'parking_alerts',
          'Parking Alerts',
          description: 'General parking notifications',
          importance: Importance.high,
          playSound: true,
        ),
      );

      // Request permissions
      await androidPlugin.requestNotificationsPermission();
    }

    // Check if app was launched via notification tap
    final NotificationAppLaunchDetails? launchDetails =
      await _notifications.getNotificationAppLaunchDetails();
    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      pendingNotificationPayload = launchDetails.notificationResponse?.payload;
    }
  }

  static void handleNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;

    final parts = payload.split(':');
    final type = parts[0];

    final navigator = AASTParkingApp.navigatorKey.currentState;
    if (navigator == null) {
      pendingNotificationPayload = payload;
      return;
    }

    switch (type) {
      case 'expiry_warning':
      case 'grace_period_cancelled':
      case 'permit_revocation_cancelled':
        navigator.pushNamed('/bookings');
        break;
      case 'waitlist_available':
        navigator.pushNamed('/map');
        break;
      case 'permit_granted':
      case 'permit_revoked':
        navigator.pushNamed('/profile');
        break;
      case 'appeal_approved':
      case 'appeal_rejected':
        navigator.pushNamed('/appeals');
        break;
    }
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
      bookingId.hashCode,
      '⏰ Parking Expiring Soon',
      'Your booking for spot $spotCode expires at $endTime. '
      'Move your car to avoid penalties.',
      details,
      payload: 'expiry_warning:$bookingId',
    );
  }
}
