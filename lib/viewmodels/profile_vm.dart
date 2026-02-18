import 'dart:convert';
import 'package:dd_grab/config/api_config.dart';
import 'package:dd_grab/view/welcome.dart';
import 'package:dd_grab/viewmodels/address_vm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

final profileViewModelProvider = ChangeNotifierProvider(
  (ref) => ProfileViewModel(),
);

class ProfileViewModel extends ChangeNotifier {
  String name = "Guest";
  String lastname = "";
  String username = "";
  String email = "";
  String phone = "";

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
    final secureStorage = const FlutterSecureStorage();
    final token = await secureStorage.read(key: 'USER_TOKEN');

    if (token == null) {
      debugPrint('No token found - clearing profile data');
      _clearProfileData();
      return;
    }

    if (_hasFetchedProfileData) return;
    
    debugPrint('Token: $token');

    final url = Uri.parse(ApiConfig.userProfile);

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
      debugPrint("Logout finished, navigating to WelcomePage");

      // Navigate first
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => WelcomePage()),
      ).then((_) {
        // Clear profile data and addresses after navigation completes
        _clearProfileData();
        ref.read(addressViewModelProvider.notifier).clearAddresses();
        debugPrint("Profile data and addresses cleared after navigation");
      });
    } catch (e) {
      _isLoggingOut = false;
      notifyListeners();
      debugPrint("Logout failed: $e");
    }
  }

  void clearProfileData() {
    name = "Guest";
    lastname = "";
    username = "";
    email = "";
    phone = "";
    _hasFetchedProfileData = false;
    notifyListeners();
  }

  void _clearProfileData() {
    clearProfileData();
  }
}
