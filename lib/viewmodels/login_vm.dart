import 'dart:convert';
import 'package:dd_grab/config/api_config.dart';
import 'package:dd_grab/view/main_navigation_page.dart';
import 'package:dd_grab/viewmodels/bottom_nav_bar_vm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

final loginViewModelProvider = ChangeNotifierProvider(
  (ref) => LoginViewModel(),
);

class LoginViewModel extends ChangeNotifier {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  final _secureStorage = const FlutterSecureStorage();

  Future<void> login(BuildContext context, WidgetRef ref) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage(context, 'Please fill in all fields');
      return;
    }

    isLoading = true;
    notifyListeners();

    final url = Uri.parse(ApiConfig.authLogin);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'loginInput': email, 'password': password}),
      );

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final token = responseData['data']['token'];
        print('Logged in token: $token');
        await _secureStorage.write(key: 'USER_TOKEN', value: token);
        ref.read(bottomNavProvider.notifier).setIndex(0);
        // Navigate to main app screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainNavigationPage()),
          (route) => false,
        );
        clearControllers();
      } else {
        final responseData = jsonDecode(response.body);
        _showMessage(context, responseData['message'] ?? 'Login failed');
      }
    } catch (e) {
      _showMessage(context, 'Error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearControllers() {
    emailController.clear();
    passwordController.clear();
  }

  void _showMessage(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.black87,
        behavior:
            SnackBarBehavior.floating, // optional: makes it float above bottom
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
