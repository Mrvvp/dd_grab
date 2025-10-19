// lib/features/orders/data/models/order_model.dart

class OrderModel {
  final int orderId;
  final String orderTotal;
  final String orderStatus;
  final String orderDate;
  final List<ProductModel> products;

  OrderModel({
    required this.orderId,
    required this.orderTotal,
    required this.orderStatus,
    required this.orderDate,
    required this.products,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json['order_id'] ?? 0,
      orderTotal: json['order_total'] ?? '0.0',
      orderStatus: json['order_status'] ?? '',
      orderDate: json['order_date'] ?? '',
      products:
          (json['products'] as List? ?? [])
              .map((product) => ProductModel.fromJson(product))
              .toList(),
    );
  }
}

class ProductModel {
  final int productId;
  final String productName;
  final List<String> productImages;
  final int quantity;
  final String unitPrice;
  final String lineTotal;

  ProductModel({
    required this.productId,
    required this.productName,
    required this.productImages,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      productImages: (json['product_images'] as List? ?? []).cast<String>(),
      quantity: json['quantity'] ?? 0,
      unitPrice: json['unit_price'] ?? '0.0',
      lineTotal: json['line_total'] ?? '0.0',
    );
  }
}
