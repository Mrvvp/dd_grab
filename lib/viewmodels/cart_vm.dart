import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

final cartViewModelProvider = ChangeNotifierProvider((ref) => CartViewModel());

class CartViewModel extends ChangeNotifier {
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final String _baseUrl =
      'https://dd-api.codesprint.cloud/api/v1'; // Replace with your actual base URL

  // Updated Getters for calculations
  double get subtotalAmount => cartItems.fold(0.0, (sum, item) {
    final price =
        double.tryParse(item['selling_price']?.toString() ?? '') ?? 0.0;
    final qty = item['quantity'] ?? 1;
    return sum + (price * qty);
  });

  double get totalAmount => subtotalAmount;

  CartViewModel() {
    fetchCart();
  }

  // UPDATED METHOD TO USE THE NEW ENDPOINT
  Future<void> fetchCart() async {
    print('[DEBUG] fetchCart() called'); // ✅ Trigger confirmation

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final secureStorage = const FlutterSecureStorage();
      final token = await secureStorage.read(key: 'USER_TOKEN');

      print('[DEBUG] Retrieved USER_TOKEN: $token'); // ✅ Check token

      if (token!.isEmpty) {
        _errorMessage = 'User not authenticated.';
        print('[DEBUG] No token found. Exiting fetchCart()'); // ✅ Token issue
        _isLoading = false;
        notifyListeners();
        return;
      }

      final url = Uri.parse('$_baseUrl/cart');
      print('[DEBUG] Sending GET request to: $url'); // ✅ URL log

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('[DEBUG] Status Code: ${response.statusCode}'); // ✅ Response status
      print('[DEBUG] Raw Response Body: ${response.body}'); // ✅ Raw JSON

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        final data = responseData['data'];
        if (data != null && data['products'] is List) {
          _cartItems =
              List<Map<String, dynamic>>.from(data['products']).map((item) {
                // Ensure quantity is always an int
                item['quantity'] =
                    int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
                return item;
              }).toList();

          print('[DEBUG] Cart item count: ${_cartItems.length}');
        } else {
          _cartItems = [];
          print('[DEBUG] data["products"] is missing or not a List');

          // ✅ Structure mismatch
        }
      } else {
        _errorMessage = 'Failed to fetch cart: ${response.statusCode}';
        print('[DEBUG] Error response: $_errorMessage'); // ✅ Error handling
      }
    } catch (e, stackTrace) {
      _errorMessage = 'An error occurred: $e';
      print('[DEBUG] Exception occurred: $e'); // ✅ Exception
      print('[DEBUG] Stack trace: $stackTrace'); // ✅ Stack trace
    } finally {
      _isLoading = false;
      notifyListeners();
      print('[DEBUG] fetchCart() completed'); // ✅ Method completed
    }
  }

  Future<void> addToCart({
    required String productId,
    required int quantity,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final secureStorage = const FlutterSecureStorage();
      final token = await secureStorage.read(key: 'USER_TOKEN');

      if (token!.isEmpty) {
        _errorMessage = 'User not authenticated.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Construct the URL with the product ID as a path variable
      final url = Uri.parse('$_baseUrl/cart/add-to-cart/$productId');

      // Send the POST request without a JSON body
      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          // Success! We don't need to process a 'data' field,
          // we simply confirm the item was added.
          // Now, fetch the updated cart data.
          await fetchCart();
        } else {
          _errorMessage =
              'API error: ${responseData['message'] ?? 'Unknown error'}';
        }
      } else {
        _errorMessage =
            'Failed to add to cart: Server responded with status code ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateCartItemQuantity(dynamic itemId, int newQty) {
    final index = _cartItems.indexWhere(
      (item) => item['id'].toString() == itemId.toString(),
    );
    if (index != -1) {
      _cartItems[index]['quantity'] = newQty;
      notifyListeners();
    }
  }

  Future<void> removeCartItem(String productId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final secureStorage = const FlutterSecureStorage();
      final token = await secureStorage.read(key: 'USER_TOKEN');

      if (token!.isEmpty) {
        _errorMessage = 'User not authenticated.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final url = Uri.parse('$_baseUrl/cart/remove-from-cart/$productId');

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          await fetchCart(); // Refresh cart after deletion
        } else {
          _errorMessage =
              'API error: ${responseData['message'] ?? 'Unknown error'}';
        }
      } else {
        _errorMessage =
            'Failed to remove item: Status code ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
