import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.5, curve: Curves.easeIn)),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.elasticOut)),
    );
    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    final isLoggedIn = await AuthService.isLoggedIn();
    if (!mounted) return;
    if (!isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    final admin = await AuthService.isAdmin();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, admin ? '/admin-home' : '/home');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 10))],
                          ),
                          child: const Icon(Icons.local_parking, size: 80, color: AppColors.primary),
                        ),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10)],
                          ),
                          child: const Icon(Icons.directions_car, size: 32, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text('AAST Parking', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 8),
                  const Text('Smart Parking System', style: TextStyle(fontSize: 18, color: Colors.white70)),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'Arab Academy for Science & Technology',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 60),
                  const CircularProgressIndicator(color: Colors.white70, strokeWidth: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
