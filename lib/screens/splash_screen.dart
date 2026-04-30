import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../utils/constants.dart';
import 'auth_check_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    print('SplashScreen: Starting 2s timer');
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      print('SplashScreen: Navigating to /auth-check');
      try {
        Navigator.of(context).pushReplacementNamed('/auth-check');
      } catch (e) {
        print('SplashScreen: Navigation failed: $e');
        // Fallback navigation
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthCheckScreen()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.primaryRed,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_rounded,
              size: 120,
              color: AppTheme.white,
            ),
            SizedBox(height: 24),
            Text(
              AppConstants.appName,
              style: TextStyle(
                color: AppTheme.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
