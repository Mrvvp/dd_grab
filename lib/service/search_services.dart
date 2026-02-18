import 'dart:convert';
import 'package:dd_grab/config/api_config.dart';
import 'package:dd_grab/models/product_model.dart';
import 'package:http/http.dart' as http;

class ProductRepository {
  ProductRepository();

  Future<List<Product>> searchProducts(
    String query, {
    int page = 1,
    int limit = 15,
    String sortBy = 'price',
    String sortOrder = 'desc',
  }) async {
    final url = Uri.parse(
      '${ApiConfig.searchProduct}?q=$query&page=$page&limit=$limit&sortBy=$sortBy&sortOrder=$sortOrder',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      List productsJson = body['data'] ?? [];
      return productsJson.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }
}
