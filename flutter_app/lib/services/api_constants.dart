class ApiConstants {
  // Change this to your server IP when testing on a physical device
  // For Android emulator use: http://10.0.2.2:3000/api
  // For iOS simulator use: http://localhost:3000/api
  // For physical device use: http://YOUR_COMPUTER_IP:3000/api
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // Auth endpoints
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';

  // Spots endpoints
  static const String spots = '$baseUrl/spots';
  static String spotById(String id) => '$baseUrl/spots/$id';

  // Bookings endpoints
  static const String bookings = '$baseUrl/bookings';
  static const String myBookings = '$baseUrl/bookings/my';
  static String cancelBooking(String id) => '$baseUrl/bookings/$id/cancel';

  // Notifications endpoints
  static const String notifications = '$baseUrl/notifications';
  static const String readAllNotifications = '$baseUrl/notifications/read-all';
  static String readNotification(String id) => '$baseUrl/notifications/$id/read';

  // Waiting list endpoints
  static const String myQueue = '$baseUrl/waitinglist/my';
  static const String joinQueue = '$baseUrl/waitinglist/join';
  static const String leaveQueue = '$baseUrl/waitinglist/leave';

  // Profile
  static const String profile = '$baseUrl/profile';
}
