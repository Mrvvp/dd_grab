import 'package:dd_grab/config/api_config.dart';

class Product {
  final String id;
  final String name;
  final String image;
  final double rating;
  final int ratingCount;
  final double price;
  final double specialPrice;
  final double mrp;
  final bool isWishlisted;

  Product({
    required this.id,
    required this.name,
    required this.image,
    required this.rating,
    required this.ratingCount,
    required this.price,
    required this.specialPrice,
    required this.mrp,
    this.isWishlisted = false,
  });

  Product copyWith({
    String? id,
    String? name,
    String? image,
    double? rating,
    int? ratingCount,
    double? price,
    double? specialPrice,
    double? mrp,
    bool? isWishlisted,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      price: price ?? this.price,
      specialPrice: specialPrice ?? this.specialPrice,
      mrp: mrp ?? this.mrp,
      isWishlisted: isWishlisted ?? this.isWishlisted,
    );
  }

  // A more resilient fromJson factory constructor
  factory Product.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? images = json['images'];
    final String imageUrl =
        (images != null && images.isNotEmpty)
            ? ApiConfig.getImageUrl(images.first.toString())
            : '';

    // ✅ CRITICAL FIX: Handle both int (0/1) and bool (true/false)
    bool parseWishlistStatus(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value == 1; // ← MUST have this!
      if (value is String) return value == '1' || value.toLowerCase() == 'true';
      return false;
    }

    return Product(
      id: (json['id'] ?? 0).toString(),
      name: json['name'] ?? json['slug'] ?? 'Unknown Product',
      image: imageUrl,
      rating: double.tryParse(json['rating']?.toString() ?? '') ?? 0.0,
      ratingCount: int.tryParse(json['rating_count']?.toString() ?? '') ?? 0,
      price: double.tryParse(json['selling_price']?.toString() ?? '') ?? 0.0,
      specialPrice:
          double.tryParse(json['special_price']?.toString() ?? '') ?? 0.0,
      mrp: double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      isWishlisted: parseWishlistStatus(
        json['in_wishlist'],
      ), // ✅ Use robust parser
    );
  }
}
