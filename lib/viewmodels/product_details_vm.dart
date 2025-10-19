import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

// The ViewModel that manages the state for the Product Details page.
class ProductDetailsViewModel extends ChangeNotifier {
  // Product details state
  Map<String, dynamic>? _productDetails;
  bool _isLoading = false;
  String? _errorMessage;

  // Selected options state
  String? _selectedStorage;
  String _enteredPincode = '';

  bool _isPincodeLoading = false;
  bool? _isPincodeValid;
  String? _pincodeErrorMessage;

  // Getters for state
  Map<String, dynamic>? get productDetails => _productDetails;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedStorage => _selectedStorage;
  String get enteredPincode => _enteredPincode;
  bool get isPincodeLoading => _isPincodeLoading;
  bool? get isPincodeValid => _isPincodeValid;
  String? get pincodeErrorMessage => _pincodeErrorMessage;

  // API endpoint
  final String _baseUrl =
      'https://dd-api.codesprint.cloud/api/v1/product/product-by-id';

  final String _pincodeCheckUrl =
      'https://dd-api.codesprint.cloud/api/v1/product/check-pincode';

  // Method to fetch product details from the API
  Future<void> fetchProductDetails(String productId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('$_baseUrl/$productId'));
      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(response.body);
        _productDetails = jsonMap['data'];
      } else {
        _errorMessage = 'Failed to load product: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Method to select a storage option
  void selectStorage(String storage) {
    if (_selectedStorage == storage) {
      _selectedStorage = null; // Deselect if already selected
    } else {
      _selectedStorage = storage;
    }
    notifyListeners();
  }

  // Method to set the pincode
  void setPincode(String pincode) {
    _enteredPincode = pincode;
    // Reset pincode validation when user changes pincode
    _isPincodeValid = null;
    _pincodeErrorMessage = null;
    notifyListeners();
  }

  // Method to check pincode delivery availability
  Future<void> checkPincode() async {
    if (_enteredPincode.isEmpty || _enteredPincode.length != 6) {
      _pincodeErrorMessage = 'Please enter a valid 6-digit pincode';
      notifyListeners();
      return;
    }

    _isPincodeLoading = true;
    _pincodeErrorMessage = null;
    _isPincodeValid = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(_pincodeCheckUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pincode': _enteredPincode}),
      );

      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(response.body);

        if (jsonMap['success'] == true) {
          _isPincodeValid = jsonMap['data']['isValid'] ?? false;

          if (!_isPincodeValid!) {
            _pincodeErrorMessage = 'Delivery not available for this pincode';
          }
        } else {
          _pincodeErrorMessage =
              jsonMap['message'] ?? 'Failed to check pincode';
          _isPincodeValid = false;
        }
      } else {
        _pincodeErrorMessage =
            'Failed to check pincode: ${response.statusCode}';
        _isPincodeValid = false;
      }
    } catch (e) {
      _pincodeErrorMessage = 'An error occurred: $e';
      _isPincodeValid = false;
    } finally {
      _isPincodeLoading = false;
      notifyListeners();
    }
  }

  // Reset pincode check
  void resetPincodeCheck() {
    _enteredPincode = '';
    _isPincodeValid = null;
    _pincodeErrorMessage = null;
    notifyListeners();
  }
}

// The Riverpod provider for the ProductDetailsViewModel.
// This allows the UI to access and listen to the ViewModel's state.
final productDetailsProvider = ChangeNotifierProvider<ProductDetailsViewModel>((
  ref,
) {
  return ProductDetailsViewModel();
});
