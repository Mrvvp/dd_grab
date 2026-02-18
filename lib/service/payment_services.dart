import 'dart:convert';
import 'package:dd_grab/config/api_config.dart';
import 'package:http/http.dart' as http;

class NoAddressException implements Exception {
  final String message;
  NoAddressException(this.message);
}

class EmptyCartException implements Exception {
  final String message;
  EmptyCartException(this.message);
}

class PaymentService {
  /// ✅ For single product (from product page)
  Future<Map<String, dynamic>> initiateOrder({
    required String userToken,
    int? productId,
    int? quantity,
  }) async {
    try {
      Map<String, dynamic>? orderData;

      // 👇 If productId and qty are passed, build body (Buy Now)
      if (productId != null && quantity != null) {
        orderData = {'product_id': productId, 'quantity': quantity};
        print('📤 [API CALL] Initiating SINGLE PRODUCT order...');
      } else {
        print('📤 [API CALL] Initiating CART order...');
      }

      print('➡ URL: ${ApiConfig.orderInitiate}');
      print('➡ Headers: {Authorization: Bearer $userToken}');
      if (orderData != null)
        print('➡ Body: ${jsonEncode(orderData)}');
      else
        print('➡ No Body (cart handled on server side)');

      final response = await http.post(
        Uri.parse(ApiConfig.orderInitiate),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
        body: orderData != null ? jsonEncode(orderData) : null,
      );

      print('📥 [API RESPONSE] Status Code: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          print('✅ Order Initiated Successfully');
          return Map<String, dynamic>.from(responseData['data']);
        } else {
          throw Exception('API returned success=false or missing data');
        }
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);

        // ✅ Check for "No default address found" message
        if (errorData['message'] == 'No default address found') {
          throw NoAddressException('Please add a delivery address to proceed');
        }

        if (errorData['message'] == 'Your cart is empty') {
          throw EmptyCartException('Your cart is empty');
        }

        throw Exception(
          'Failed to initiate order: ${errorData['message'] ?? response.body}',
        );
      } else {
        throw Exception(
          'Failed to initiate order: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e is NoAddressException || e is EmptyCartException) rethrow;
      print('❌ Exception in initiateOrder(): $e');
      throw Exception('Error initiating order: $e');
    }
  }

  /// ✅ Confirm Order (after successful payment)
  Future<void> confirmOrder({
    required String userToken,
    required int orderId,
    required String cfOrderId,
    required String paymentStatus,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.orderConfirm),
        headers: {
          'Authorization': 'Bearer $userToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'order_id': orderId,
          'cf_order_id': cfOrderId,
          'payment_status': paymentStatus,
        }),
      );

      print('Confirm Order API Response: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception('Order confirmation failed: ${response.body}');
      }
    } catch (e) {
      print('❌ Error in confirmOrder: $e');
      rethrow;
    }
  }
}
