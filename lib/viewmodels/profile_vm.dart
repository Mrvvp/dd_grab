import 'package:dd_grab/view/loginpage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

final profileViewModelProvider = ChangeNotifierProvider(
  (ref) => ProfileViewModel(),
);

class ProfileViewModel extends ChangeNotifier {
  String name = "Delight Benedict";
  String lastname = "";
  String username = "";
  String email = "delightmben@gmail.com";
  String phone = "9995300000";

  bool _hasFetchedProfileData = false;
  bool _isLoggingOut = false; // NEW

  bool get isLoggingOut => _isLoggingOut; // Getter

  void editProfile(
    String newName,
    String newEmail,
    String newPhone,
    String newLastname,
    String newusername,
  ) {
    name = newName;
    lastname = newLastname;
    username = newusername;

    email = newEmail;
    phone = newPhone;
    notifyListeners();
  }

  Future<void> fetchProfileData() async {
    if (_hasFetchedProfileData) return;

    final secureStorage = const FlutterSecureStorage();
    final token = await secureStorage.read(key: 'USER_TOKEN');

    if (token == null) {
      debugPrint('No token found in SharedPreferences');
      return;
    }
    debugPrint('Token: $token');

    final url = Uri.parse(
      'https://dd-api.codesprint.cloud/api/v1/user/profile',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final userData = responseData['data'];

        name = userData['first_name'];
        lastname = userData['last_name'];
        email = userData['email'];
        phone = userData['phone'];
        lastname = userData['last_name'];
        username = userData['username'];
        _hasFetchedProfileData = true;
        notifyListeners();
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      debugPrint('Error fetching profile data: $e');
    }
  }

  Future<void> refreshProfileData() async {
    _hasFetchedProfileData = false;
    await fetchProfileData();
  }

  Future<void> logout(BuildContext context, WidgetRef ref) async {
    _isLoggingOut = true;
    notifyListeners();
    debugPrint("Logout started");

    try {
      await Future.delayed(const Duration(seconds: 2));
      const storage = FlutterSecureStorage();
      await storage.delete(key: 'USER_TOKEN');
      debugPrint("JWT token deleted");

      _isLoggingOut = false;
      notifyListeners();
      debugPrint("Logout finished, navigating to LoginPage");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );

      debugPrint("Bottom nav index reset");
    } catch (e) {
      _isLoggingOut = false;
      notifyListeners();
      debugPrint("Logout failed: $e");
    }
  }
}
