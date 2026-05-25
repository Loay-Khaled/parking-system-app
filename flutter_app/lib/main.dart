import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
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
import 'models/booking.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AASTParkingApp());
}

class AASTParkingApp extends StatelessWidget {
  const AASTParkingApp({super.key});

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
          default:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
      },
    );
  }
}
