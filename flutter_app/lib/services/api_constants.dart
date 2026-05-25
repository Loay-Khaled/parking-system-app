import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android emulator loopback IP
        return 'http://10.0.2.2:3000/api';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return 'http://localhost:3000/api';
    }
  }

  // Auth endpoints
  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';

  // Spots endpoints
  static String get spots => '$baseUrl/spots';
  static String spotById(String id) => '$baseUrl/spots/$id';

  // Bookings endpoints
  static String get bookings => '$baseUrl/bookings';
  static String get myBookings => '$baseUrl/bookings/my';
  static String cancelBooking(String id) => '$baseUrl/bookings/$id/cancel';

  // Notifications endpoints
  static String get notifications => '$baseUrl/notifications';
  static String get readAllNotifications => '$baseUrl/notifications/read-all';
  static String readNotification(String id) => '$baseUrl/notifications/$id/read';

  // Waiting list endpoints
  static String get myQueue => '$baseUrl/waitinglist/my';
  static String get joinQueue => '$baseUrl/waitinglist/join';
  static String get leaveQueue => '$baseUrl/waitinglist/leave';
  static String get acceptQueue => '$baseUrl/waitinglist/accept';
  static String get declineQueue => '$baseUrl/waitinglist/decline';

  // Profile
  static String get profile => '$baseUrl/profile';

  // ADMIN endpoints
  static String get adminStats => '$baseUrl/admin/stats';
  static String get adminUsers => '$baseUrl/admin/users';
  static String adminDeleteUser(String id) => '$baseUrl/admin/users/$id';
  static String get adminBookings => '$baseUrl/admin/bookings';
  static String adminCancelBooking(String id) => '$baseUrl/admin/bookings/$id/cancel';
  static String get adminSpots => '$baseUrl/admin/spots';
  static String adminUpdateSpotStatus(String spotId) => '$baseUrl/admin/spots/$spotId/status';
  static String get adminSendNotification => '$baseUrl/admin/notifications/send';
}
