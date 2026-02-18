import 'dart:convert';
import 'package:dd_grab/config/api_config.dart';
import 'package:dd_grab/view/loginpage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// ✅ Riverpod provider for SignUpViewModel
final signUpViewModelProvider = ChangeNotifierProvider<SignUpViewModel>(
  (ref) => SignUpViewModel(),
);

class SignUpViewModel extends ChangeNotifier {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoading = false;

  /// ✅ Signup function using HTTP POST
  Future<void> signup(BuildContext context, WidgetRef ref) async {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // ✅ Validation
    if ([
      firstName,
      lastName,
      username,
      email,
      phone,
      password,
      confirmPassword,
    ].any((e) => e.isEmpty)) {
      _showMessage(context, 'Please fill in all fields');
      return;
    }

    if (password != confirmPassword) {
      _showMessage(context, 'Passwords do not match');
      return;
    }

    isLoading = true;
    notifyListeners();

    final url = Uri.parse(ApiConfig.authSignup);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'first_name': firstName,
          'last_name': lastName,
          'username': username,
          'email': email,
          'phone': phone,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        _showMessage(context, 'Account created successfully!');
        _clearControllers();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      } else {
        _showMessage(context, data['message'] ?? 'Signup failed');
      }
    } catch (e) {
      _showMessage(context, 'Error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearControllers() {
    firstNameController.clear();
    lastNameController.clear();
    usernameController.clear();
    emailController.clear();
    phoneController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
  }

  void _clearControllers() {
    clearControllers();
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
