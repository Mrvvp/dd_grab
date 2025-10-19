import 'package:dd_grab/models/address_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final addressViewModelProvider =
    StateNotifierProvider<AddressViewModel, AddressState>((ref) {
      return AddressViewModel(ref); // Pass ref to access other providers
    });

final addressFormProvider = StateProvider<Map<String, String>>(
  (ref) => {
    'first_name': '',
    'last_name': '',
    'address_1': '',
    'address_2': '',
    'city': '',
    'state': '',
    'zip': '',
    'country': '',
  },
);

class AddressViewModel extends StateNotifier<AddressState> {
  final Ref ref; // To access other providers like addressFormProvider

  AddressViewModel(this.ref) : super(AddressState.initial());

  Future<void> fetchAddresses({bool forceRefresh = false}) async {
    if (state.addresses.isNotEmpty && !forceRefresh) return;

    state = state.copyWith(isLoading: true, error: '');

    try {
      final secureStorage = const FlutterSecureStorage();
      final token = await secureStorage.read(key: 'USER_TOKEN');

      final uri = Uri.parse(
        "https://dd-api.codesprint.cloud/api/v1/user/get-addresses",
      );
      print('Fetching addresses from: $uri');
      print('Using token: $token');

      // ✅ Check if token is null or empty
      if (token == null || token.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: '', // Don't show error for guests
          addresses: [], // Empty list for guests
        );
        print('Guest user - no addresses to fetch');
        return;
      }

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // ✅ Handle 401 Unauthorized
      if (response.statusCode == 401) {
        state = state.copyWith(
          isLoading: false,
          error: 'Session expired',
          addresses: [],
        );
        // Optionally clear invalid token
        await secureStorage.delete(key: 'USER_TOKEN');
        print('Token expired - cleared');
        return;
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final addresses =
              (data['data'] as List)
                  .map((json) => Address.fromJson(json))
                  .toList();

          state = state.copyWith(
            isLoading: false,
            addresses: addresses,
            error: '',
          );
          print('✅ Loaded ${addresses.length} addresses');
        } else {
          state = state.copyWith(
            isLoading: false,
            error: 'Failed to load addresses',
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      print('Error fetching addresses: $e');
    }
  }

  // New: Initialize form data (moved from widget)
  void initializeForm(Address? address) {
    ref.read(addressFormProvider.notifier).state =
        address != null
            ? {
              'first_name': address.firstName,
              'last_name': address.lastName,
              'address_1': address.address1,
              'address_2': address.address2,
              'city': address.city,
              'state': address.state,
              'zip': address.zip,
              'country': address.country,
            }
            : {
              'first_name': '',
              'last_name': '',
              'address_1': '',
              'address_2': '',
              'city': '',
              'state': '',
              'zip': '',
              'country': '',
            };
  }

  // New: Update a single form field
  void updateFormField(String key, String value) {
    final currentForm = ref.read(addressFormProvider);
    ref.read(addressFormProvider.notifier).state = {...currentForm, key: value};
  }

  // New: Validate and save (moved from widget)
  Future<String?> validateAndSave(int? addressId) async {
    final formData = ref.read(addressFormProvider);

    for (final entry in formData.entries) {
      if (entry.value.trim().isEmpty) {
        return '${entry.key.replaceAll('_', ' ').toUpperCase()} is required';
      }
    }

    String? errorMsg;
    if (addressId != null) {
      // Edit address
      errorMsg = await editAddress(addressId, formData);
    } else {
      // Add address
      errorMsg = await addAddress(formData);
    }

    if (errorMsg == null) {
      // Reset form after successful save
      ref.read(addressFormProvider.notifier).state = {
        'first_name': '',
        'last_name': '',
        'address_1': '',
        'address_2': '',
        'city': '',
        'state': '',
        'zip': '',
        'country': '',
      };
    }

    return errorMsg;
  }

  Future<String?> addAddress(Map<String, String> formData) async {
    try {
      final secureStorage = const FlutterSecureStorage();
      final token = await secureStorage.read(key: 'USER_TOKEN');

      if (token!.isEmpty) {
        return 'Auth token missing.';
      }

      final response = await http.post(
        Uri.parse("https://dd-api.codesprint.cloud/api/v1/user/add-address"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(formData),
      );

      print('Request Body: ${json.encode(formData)}');
      print('Response Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 ||
          response.statusCode == 201 && data['success'] == true) {
        await fetchAddresses(forceRefresh: true);
        return null; // No error
      } else {
        return data['message'] ?? 'Something went wrong.';
      }
    } catch (e) {
      return 'Add Address Error: $e';
    }
  }

  Future<String?> editAddress(int id, Map<String, String> formData) async {
    try {
      final secureStorage = const FlutterSecureStorage();
      final token = await secureStorage.read(key: 'USER_TOKEN');

      final response = await http.put(
        Uri.parse(
          "https://dd-api.codesprint.cloud/api/v1/user/edit-address/$id",
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(formData),
      );

      if (response.statusCode == 200) {
        await fetchAddresses();
        return null;
      } else {
        final body = json.decode(response.body);
        return body['message'] ?? 'Failed to update address';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String?> setDefaultAddress(int id) async {
    try {
      final secureStorage = const FlutterSecureStorage();
      final token = await secureStorage.read(key: 'USER_TOKEN');

      if (token!.isEmpty) {
        return 'Auth token missing.';
      }

      final response = await http.put(
        Uri.parse(
          "https://dd-api.codesprint.cloud/api/v1/user/set-default-address/$id",
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = json.decode(response.body);
      print('Set Default Response: ${response.body}');

      if (response.statusCode == 200 && data['success'] == true) {
        await fetchAddresses(forceRefresh: true); // Refresh UI
        return null;
      } else {
        return data['message'] ?? 'Failed to set default address';
      }
    } catch (e) {
      return 'Set Default Error: $e';
    }
  }

  Future<String?> deleteAddress(int id) async {
    try {
      final secureStorage = const FlutterSecureStorage();
      final token = await secureStorage.read(key: 'USER_TOKEN');

      if (token == null || token.isEmpty) {
        return 'Auth token missing.';
      }

      final response = await http.delete(
        Uri.parse(
          "https://dd-api.codesprint.cloud/api/v1/user/delete-address/$id",
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Delete Response Code: ${response.statusCode}');
      print('Delete Response Body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        await fetchAddresses(forceRefresh: true);
        return null; // success → no error
      } else {
        return data['message'] ?? 'Failed to delete address';
      }
    } catch (e) {
      return 'Delete Address Error: $e';
    }
  }
}

class AddressState {
  final List<Address> addresses;
  final bool isLoading;
  final String error;

  AddressState({
    required this.addresses,
    required this.isLoading,
    required this.error,
  });

  factory AddressState.initial() =>
      AddressState(addresses: [], isLoading: false, error: '');

  AddressState copyWith({
    List<Address>? addresses,
    bool? isLoading,
    String? error,
  }) {
    return AddressState(
      addresses: addresses ?? this.addresses,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
