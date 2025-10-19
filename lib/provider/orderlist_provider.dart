// lib/features/orders/view_model/order_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dd_grab/models/order_model.dart';
import 'package:dd_grab/service/orderlist_services.dart';

// Repository Provider
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

// FutureProvider for Order List
final orderListProvider = FutureProvider<List<OrderModel>>((ref) async {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.fetchOrders();
});
