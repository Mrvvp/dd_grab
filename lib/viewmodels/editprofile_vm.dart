import 'dart:convert';
import 'package:dd_grab/main.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final editProfileViewModelProvider = ChangeNotifierProvider(
  (ref) => EditProfileViewModel(),
);

class EditProfileViewModel extends ChangeNotifier {
  final nameController = TextEditingController();
  final lastname = TextEditingController();
  final username = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool loading = false;
  bool isloading = false;
  bool initialized = false;
  final _secureStorage = const FlutterSecureStorage();

  Future<bool> editProfile() async {
    if (nameController.text.trim().isEmpty ||
        lastname.text.trim().isEmpty ||
        username.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty) {
      loading = false;
      notifyListeners();
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    bool updated = false;
    loading = true;
    notifyListeners();

    final secureStorage = const FlutterSecureStorage();
    final token = await secureStorage.read(key: 'USER_TOKEN');

    if (token == null) {
      debugPrint('Token not found in SharedPreferences');
      loading = false;
      notifyListeners();
      return updated;
    }

    final url = Uri.parse(
      'https://dd-api.codesprint.cloud/api/v1/user/edit-profile',
    );

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'first_name': nameController.text.trim(),
          'last_name': lastname.text.trim(),
          'username': username.text.trim(),
          'email': emailController.text.trim(),
          'phone': phoneController.text.trim(),
        }),
      );

      debugPrint(
        'Request Body: ${jsonEncode({'first_name': nameController.text.trim(), 'last_name': lastname.text.trim(), 'username': username.text.trim(), 'email': emailController.text.trim(), 'phone': phoneController.text.trim()})}',
      );
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('Profile updated successfully');
        updated = true;
        await fetchProfile();
      } else {
        debugPrint('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error while updating profile: $e');
    }

    loading = false;
    notifyListeners();
    return updated;
  }

  Future<void> fetchProfile() async {
    final secureStorage = const FlutterSecureStorage();
    final token = await secureStorage.read(key: 'USER_TOKEN');

    if (token == null) return;

    final url = Uri.parse(
      'https://dd-api.codesprint.cloud/api/v1/user/profile',
    );
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        nameController.text = data['first_name'] ?? '';
        lastname.text = data['last_name'] ?? '';
        username.text = data['username'] ?? '';
        emailController.text = data['email'] ?? '';
        phoneController.text = data['phone'] ?? '';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to fetch profile: $e');
    }
  }

  Future<void> changePassword(BuildContext context, String newPassword) async {
    isloading = true;
    notifyListeners();

    final token = await _secureStorage.read(key: 'USER_TOKEN');
    final url = Uri.parse(
      'https://dd-api.codesprint.cloud/api/v1/auth/change-password',
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'newPassword': newPassword}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _showMessage(context, 'Password changed successfully');
        } else {
          _showMessage(context, 'Failed to change password');
        }
      } else {
        _showMessage(context, 'Error: ${response.statusCode}');
      }
    } catch (e) {
      _showMessage(context, 'Error: $e');
    } finally {
      isloading = false;
      notifyListeners();
    }
  }

  void _showMessage(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontSize: 16.0, color: Colors.white),
        ),
        backgroundColor: Colors.black87,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
