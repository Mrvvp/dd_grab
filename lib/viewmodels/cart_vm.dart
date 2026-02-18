import 'dart:convert';
import 'dart:math';
import 'package:dd_grab/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

final cartViewModelProvider = ChangeNotifierProvider((ref) => CartViewModel());

class CartViewModel extends ChangeNotifier {
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  bool _useWallet = false;
  double _walletAmount = 0.0;
  double _totalActiveWallet = 750.25; // Mock data
  double _totalUsableWallet = 500.00; // Mock data
  bool _isWalletLoading = false;
  String? _walletErrorMessage;

  List<Map<String, dynamic>> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get useWallet => _useWallet;
  double get walletAmount => _walletAmount;
  double get totalActiveWallet => _totalActiveWallet;
  double get totalUsableWallet => _totalUsableWallet;
  bool get isWalletLoading => _isWalletLoading;
  String? get walletErrorMessage => _walletErrorMessage;

  // Updated Getters for calculations
  double get subtotalAmount => cartItems.fold(0.0, (sum, item) {
    final price =
        double.tryParse(item['selling_price']?.toString() ?? '') ?? 0.0;
    final qty = item['quantity'] ?? 1;
    return sum + (price * qty);
  });

  double get totalBeforeWallet => subtotalAmount;
  double get finalTotal =>
      (totalBeforeWallet - _walletAmount).clamp(0.0, totalBeforeWallet);

  double get totalAmount => _useWallet ? finalTotal : subtotalAmount;

  CartViewModel() {
    fetchCart();
    _initializeWallet();
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

      final url = Uri.parse(ApiConfig.cart);
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
      final url = Uri.parse('${ApiConfig.addToCart}/$productId');

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

      final url = Uri.parse('${ApiConfig.removeFromCart}/$productId');

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

  Future<void> _initializeWallet() async {
    // Simulate API delay for realistic loading
    await Future.delayed(const Duration(milliseconds: 800));
    _isWalletLoading = true;
    notifyListeners();

    // Simulate another small delay
    await Future.delayed(const Duration(milliseconds: 1200));

    // Set mock wallet data
    _totalActiveWallet = 750.25;
    _totalUsableWallet = 500.00;
    _isWalletLoading = false;
    _walletErrorMessage = null;

    notifyListeners();
    print(
      '[DEBUG] Mock wallet initialized - Active: ₹${_totalActiveWallet.toStringAsFixed(2)}',
    );
  }

  void toggleWalletUsage() {
    if (_useWallet) {
      // Disable wallet usage
      _useWallet = false;
      _walletAmount = 0.0;
      _walletErrorMessage = null;
      print('[DEBUG] Wallet usage disabled (frontend only)');
    } else {
      // Enable wallet usage with suggested amount
      _useWallet = true;
      final suggestedAmount = min(_totalUsableWallet, totalBeforeWallet);
      _walletAmount = suggestedAmount;
      print(
        '[DEBUG] Wallet usage enabled with ₹${_walletAmount.toStringAsFixed(2)} (frontend only)',
      );
    }
    notifyListeners();
  }

  void updateWalletAmount(double amount) {
    if (!_useWallet) return;

    // Calculate max usable amount
    final maxUsableFromWallet = _totalUsableWallet;
    final maxUsableFromOrder = totalBeforeWallet;
    final maxUsable = min(maxUsableFromWallet, maxUsableFromOrder);

    final clampedAmount = amount.clamp(0.0, maxUsable);

    if (_walletAmount != clampedAmount) {
      _walletAmount = clampedAmount;
      _walletErrorMessage = null;

      // Simulate validation feedback
      if (clampedAmount < amount) {
        _walletErrorMessage =
            'Amount adjusted to maximum available: ₹${maxUsable.toStringAsFixed(2)}';
      }

      print(
        '[DEBUG] Wallet amount updated to: ₹${_walletAmount.toStringAsFixed(2)} (Max: ₹${maxUsable.toStringAsFixed(2)})',
      );
      notifyListeners();
    }
  }

  Future<bool> applyWalletAmount() async {
    if (!_useWallet || _walletAmount <= 0) {
      _walletErrorMessage = 'Please enter a valid wallet amount';
      notifyListeners();
      return false;
    }

    // Simulate API delay
    _isWalletLoading = true;
    _walletErrorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1500));

    // Simulate success (90% success rate for demo)
    final random = Random();
    final isSuccess = random.nextDouble() > 0.1;

    _isWalletLoading = false;

    if (isSuccess) {
      // Add to transaction history (for demo)

      print(
        '[DEBUG] Wallet applied successfully (mock): ₹${_walletAmount.toStringAsFixed(2)}',
      );
      notifyListeners();
      return true;
    } else {
      _walletErrorMessage = 'Insufficient wallet balance. Please try again.';
      print('[DEBUG] Mock wallet apply failed');
      notifyListeners();
      return false;
    }
  }

  void clearWalletUsage() {
    _useWallet = false;
    _walletAmount = 0.0;
    _walletErrorMessage = null;
    notifyListeners();
    print('[DEBUG] Wallet usage cleared (frontend only)');
  }

  void refreshWalletBalance() {
    // Simulate wallet refresh with slight variation
    _isWalletLoading = true;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 1000), () {
      // Add some random variation to simulate real data
      final random = Random();
      _totalActiveWallet = (750.25 + (random.nextDouble() - 0.5) * 50).clamp(
        100.0,
        2000.0,
      );
      _totalUsableWallet = min(
        _totalActiveWallet,
        500.0 + (random.nextDouble() - 0.5) * 100,
      );
      _isWalletLoading = false;
      _walletErrorMessage = null;
      notifyListeners();
      print('[DEBUG] Wallet balance refreshed (mock)');
    });
  }

  // Simulate adding money to wallet (for demo)
  Future<bool> addMoneyToWallet(double amount) async {
    if (amount <= 0 || amount > 10000) {
      _walletErrorMessage = 'Invalid amount. Please enter between ₹1 - ₹10,000';
      return false;
    }

    _isWalletLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 2000));

    final random = Random();
    final isSuccess = random.nextDouble() > 0.05; // 95% success

    _isWalletLoading = false;

    if (isSuccess) {
      _totalActiveWallet += amount;
      _totalUsableWallet = min(_totalActiveWallet, _totalUsableWallet + amount);

      _walletErrorMessage = null;
      return true;
    } else {
      _walletErrorMessage = 'Payment failed. Please try again.';
      return false;
    }
  }

  // Helper methods
  bool get canWalletCoverOrder =>
      _totalUsableWallet >= totalBeforeWallet && totalBeforeWallet > 0;
  double get walletCoveragePercentage =>
      totalBeforeWallet > 0
          ? ((_walletAmount / totalBeforeWallet) * 100).clamp(0.0, 100.0)
          : 0.0;

  // Check if wallet amount is valid for current order
  bool get isWalletAmountValid =>
      _useWallet && _walletAmount > 0 && _walletAmount <= _totalUsableWallet;
}
