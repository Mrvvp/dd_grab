import 'package:dd_grab/service/payment_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final int? orderId;
  final String? cfOrderId;
  final String? paymentSessionId;
  final bool paymentInProgress;

  PaymentState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.orderId,
    this.cfOrderId,
    this.paymentSessionId,
    this.paymentInProgress = false,
  });

  PaymentState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    int? orderId,
    String? cfOrderId,
    String? paymentSessionId,
    bool? paymentInProgress,
  }) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      orderId: orderId ?? this.orderId,
      cfOrderId: cfOrderId ?? this.cfOrderId,
      paymentSessionId: paymentSessionId ?? this.paymentSessionId,
      paymentInProgress: paymentInProgress ?? this.paymentInProgress,
    );
  }
}

class PaymentViewModel extends StateNotifier<PaymentState> {
  final PaymentService _paymentService = PaymentService();

  PaymentViewModel() : super(PaymentState());

  Future<void> startPaymentProcess({
    required String? userToken,
    List<Map<String, dynamic>>? cartItems,
    int? singleProductId,
    int? singleQuantity,
    required double totalAmount,
  }) async {
    state = PaymentState(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );

    if (userToken == null || userToken.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'User not logged in. Please log in again.',
      );
      return;
    }

    try {
      Map<String, dynamic> orderResponse;

      if (cartItems != null && cartItems.isNotEmpty) {
        // cart flow
        print('🛒 Processing cart order...');
        orderResponse = await _paymentService.initiateOrder(
          userToken: userToken,
        );
      } else if (singleProductId != null) {
        // single product flow
        print(
          '📦 Processing single product order - Product ID: $singleProductId',
        );
        orderResponse = await _paymentService.initiateOrder(
          userToken: userToken,
          productId: singleProductId,
          quantity: singleQuantity ?? 1,
        );
      } else {
        throw Exception('No valid order data provided');
      }

      final int orderId = orderResponse['order_id'];
      final String cfOrderId = orderResponse['cf_order_id'];
      final String paymentSessionId = orderResponse['payment_session_id'];

      print('🚀 Order initiated - ID: $orderId, CF Order: $cfOrderId');

      state = state.copyWith(
        isLoading: false,
        orderId: orderId,
        cfOrderId: cfOrderId,
        paymentSessionId: paymentSessionId,
        paymentInProgress: true,
      );
    } catch (e) {
      print('❌ Error in startPaymentProcess: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to initiate payment: ${e.toString()}',
      );
    }
  }

  /// NEW: Call this from your PaymentScreen for Buy Now flow!
  void setOrderData({
    required int orderId,
    required String cfOrderId,
    required String paymentSessionId,
  }) {
    state = state.copyWith(
      orderId: orderId,
      cfOrderId: cfOrderId,
      paymentSessionId: paymentSessionId,
      paymentInProgress: true,
      isLoading: false,
    );
  }

  Future<void> confirmPaymentOrder({
    required String? userToken,
    required String status,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      await _paymentService.confirmOrder(
        userToken: userToken!,
        orderId: state.orderId!,
        cfOrderId: state.cfOrderId!,
        paymentStatus: status,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Payment $status',
        paymentInProgress: false,
      );
    } catch (e) {
      print('❌ Error in confirmPaymentOrder: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Payment confirmation failed: ${e.toString()}',
        paymentInProgress: false,
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  void resetPayment() {
    state = PaymentState();
  }
}

final paymentViewModelProvider =
    StateNotifierProvider<PaymentViewModel, PaymentState>(
      (ref) => PaymentViewModel(),
    );
