// lib/features/orders/data/repository/order_repository.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';

class OrderRepository {
  final String baseUrl = "https://dd-api.codesprint.cloud/api/v1";
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  Future<List<OrderModel>> fetchOrders() async {
    // Read token from secure storage
    final token = await storage.read(key: "USER_TOKEN");

    if (token == null || token.isEmpty) {
      print("❌ No token found in Secure Storage");
      throw Exception("User token not found");
    }

    final url = Uri.parse("$baseUrl/order/list-order");

    print("=== Fetch Orders API Call ===");
    print("➡️ URL: $url");
    print("➡️ Token: $token");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token", // ✅ token added
      },
    );

    print("⬅️ Response Status: ${response.statusCode}");
    print("⬅️ Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List orders = data["data"] ?? [];
      print("✅ Parsed Orders: ${orders.length}");
      return orders.map((json) => OrderModel.fromJson(json)).toList();
    } else {
      print("❌ Failed to fetch orders: ${response.body}");
      throw Exception("Failed to fetch orders: ${response.body}");
    }
  }
}
