import 'dart:async';
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'services/api_service.dart';
import 'services/api_constants.dart';
import 'services/auth_service.dart';
import 'models/booking.dart';

// Import screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/spot_details_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/confirmation_screen.dart';
import 'screens/bookings_screen.dart';
import 'screens/waiting_list_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/vehicle_management_screen.dart';
import 'screens/qr_screen.dart';
import 'screens/predicted_availability_screen.dart';
import 'screens/my_appeals_screen.dart';
// accessibility_permit_screen.dart deleted — permits are now admin-only

// Admin screens
import 'screens/admin/admin_home_screen.dart';
import 'screens/admin/admin_users_screen.dart';
import 'screens/admin/admin_bookings_screen.dart';
import 'screens/admin/admin_spots_screen.dart';
import 'screens/admin/admin_notifications_screen.dart';
import 'screens/admin/analytics_screen.dart';
import 'screens/admin/admin_appeals_screen.dart';
import 'screens/admin/admin_accessibility_screen.dart';
import 'screens/admin/admin_user_detail_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AASTParkingApp());
}

class AASTParkingApp extends StatefulWidget {
  const AASTParkingApp({super.key});

  @override
  State<AASTParkingApp> createState() => _AASTParkingAppState();
}

class _AASTParkingAppState extends State<AASTParkingApp> {
  Timer? _reminderTimer;

  @override
  void initState() {
    super.initState();
    NotificationService.initializeNotifications();
    _reminderTimer = Timer.periodic(const Duration(seconds: 60), (timer) async {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) return; // not logged in, skip

      try {
        final bookings = await ApiService.get('${ApiConstants.baseUrl}/bookings/pending-reminder');

        if (bookings == null || bookings is! List) return;

        for (final booking in bookings) {
          final spotCode = (booking['spotId'] ?? booking['parkingSpotId']?['code'] ?? 'Unknown').toString();
          await NotificationService.showReminderNotification(
            bookingId: booking['_id'],
            spotCode: spotCode,
            endTime: booking['endTime'] ?? '',
          );
          await ApiService.patch(
            '${ApiConstants.baseUrl}/bookings/${booking['_id']}/acknowledge-reminder',
            {}
          );
        }
      } catch (e) {
        // Silently fail — do not crash the app if the poll fails
        debugPrint('Reminder poll error: $e');
      }
    });
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AAST Smart Parking',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/splash',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/splash':
            return MaterialPageRoute(builder: (_) => const SplashScreen());
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/register':
            return MaterialPageRoute(builder: (_) => const RegisterScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case '/map':
            return MaterialPageRoute(builder: (_) => const MapScreen());
          case '/spot-details':
            final spotId = settings.arguments as String? ?? 'A1';
            return MaterialPageRoute(builder: (_) => SpotDetailsScreen(spotId: spotId));
          case '/booking':
            final spotId = settings.arguments as String? ?? 'A1';
            return MaterialPageRoute(builder: (_) => BookingScreen(spotId: spotId));
          case '/confirmation':
            final booking = settings.arguments as Booking;
            return MaterialPageRoute(builder: (_) => ConfirmationScreen(booking: booking));
          case '/bookings':
            return MaterialPageRoute(builder: (_) => const BookingsScreen());
          case '/waiting-list':
            return MaterialPageRoute(builder: (_) => const WaitingListScreen());
          case '/notifications':
            return MaterialPageRoute(builder: (_) => const NotificationsScreen());
          case '/profile':
            return MaterialPageRoute(builder: (_) => const ProfileScreen());
          case '/wallet':
            return MaterialPageRoute(builder: (_) => const WalletScreen());
          case '/vehicles':
            return MaterialPageRoute(builder: (_) => const VehicleManagementScreen());
          case '/qr':
            final bookingId = settings.arguments as String? ?? '';
            return MaterialPageRoute(builder: (_) => QrScreen(bookingId: bookingId));
          case '/predicted-availability':
            return MaterialPageRoute(builder: (_) => const PredictedAvailabilityScreen());
          case '/appeals':
            return MaterialPageRoute(builder: (_) => const MyAppealsScreen());
          // /accessibility-permit route removed — permits are admin-assigned only
          
          // Admin routes
          case '/admin-home':
            return MaterialPageRoute(builder: (_) => const AdminHomeScreen());
          case '/admin-users':
            return MaterialPageRoute(builder: (_) => const AdminUsersScreen());
          case '/admin-bookings':
            return MaterialPageRoute(builder: (_) => const AdminBookingsScreen());
          case '/admin-spots':
            return MaterialPageRoute(builder: (_) => const AdminSpotsScreen());
          case '/admin-notifications':
            return MaterialPageRoute(builder: (_) => const AdminNotificationsScreen());
          case '/admin-analytics':
            return MaterialPageRoute(builder: (_) => const AnalyticsScreen());
          case '/admin-appeals':
            return MaterialPageRoute(builder: (_) => const AdminAppealsScreen());
          case '/admin-accessibility':
            return MaterialPageRoute(builder: (_) => const AdminAccessibilityScreen());
          case '/admin-user-detail':
            final userId = settings.arguments as String? ?? '';
            return MaterialPageRoute(builder: (_) => AdminUserDetailScreen(userId: userId));
            
          default:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
      },
    );
  }
}
