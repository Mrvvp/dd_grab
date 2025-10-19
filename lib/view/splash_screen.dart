import 'dart:async';
import 'package:dd_grab/view/main_navigation_page.dart';
import 'package:dd_grab/view/welcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Start the timer and check login status
    Timer(const Duration(seconds: 2), () {
      _checkLoginStatus();
    });
  }

  Future<void> _checkLoginStatus() async {
    try {
      final secureStorage = const FlutterSecureStorage();
      final token = await secureStorage.read(key: 'USER_TOKEN');

      if (!mounted) return;

      if (token != null && token.isNotEmpty) {
        // User is logged in, navigate to MainNavigation page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MainNavigationPage()),
        );
      } else {
        // User is not logged in, navigate to WelcomePage
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => WelcomePage()),
        );
      }
    } catch (e) {
      // Handle FlutterSecureStorage errors (BadPaddingException, etc.)
      print('❌ Error reading token: $e');

      // Clear corrupted storage
      try {
        final secureStorage = const FlutterSecureStorage();
        await secureStorage.deleteAll();
        print('✅ Cleared corrupted secure storage');
      } catch (clearError) {
        print('⚠️ Failed to clear storage: $clearError');
      }

      // Navigate to welcome page as guest
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => WelcomePage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0XFF212121),
      body: Center(
        child: Image.asset(
          'assets/images/ddgrab_icon.png', // Make sure to add this image to your assets
          fit: BoxFit.cover,
          height: 60,
        ),
      ),
    );
  }
}
