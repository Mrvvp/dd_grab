import 'package:dd_grab/provider/counter_provider.dart';
import 'package:dd_grab/viewmodels/bottom_nav_bar_vm.dart';
import 'package:dd_grab/viewmodels/purchase_vm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfdropcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:lottie/lottie.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final double totalAmount;
  final String? userToken;
  final List<Map<String, dynamic>>? cartItems;
  // NEW:
  final bool isBuyNow;
  final int? orderId;
  final String? cfOrderId;
  final String? paymentSessionId;

  // For Buy Now, pass isBuyNow: true and the order info
  // For Cart, pass isBuyNow: false and only cartItems

  const PaymentScreen({
    super.key,
    required this.totalAmount,
    required this.userToken,
    this.cartItems,
    this.isBuyNow = false,
    this.orderId,
    this.cfOrderId,
    this.paymentSessionId,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  CFPaymentGatewayService? cfPaymentGatewayService;
  bool _paymentCompleted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPayment();
    });
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentViewModelProvider);

    // listen when session becomes ready
    ref.listen(paymentViewModelProvider, (previous, current) {
      if (previous?.paymentSessionId == null &&
          current.paymentSessionId != null &&
          current.cfOrderId != null) {
        _launchCashfree(current.cfOrderId!, current.paymentSessionId!);
      }
    });

    return WillPopScope(
      onWillPop: () async {
        if (!_paymentCompleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please wait, payment is in progress...'),
              backgroundColor: Colors.black,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return false; // Block navigation
        }
        return true; // Allow navigation after payment completes
      },
      child: Scaffold(
        body: Center(
          child: Text(
            paymentState.paymentInProgress
                ? "Processing Payment..."
                : "Initializing Payment...",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  void _startPayment() {
    final paymentVm = ref.read(paymentViewModelProvider.notifier);

    paymentVm.resetPayment();

    // ✅ Check if order data exists (regardless of isBuyNow flag)
    if (widget.orderId != null &&
        widget.cfOrderId != null &&
        widget.paymentSessionId != null) {
      // ✅ Order already created - just set the data
      debugPrint('✅ Using existing order data');
      debugPrint('Order ID: ${widget.orderId}');
      debugPrint('CF Order ID: ${widget.cfOrderId}');

      paymentVm.setOrderData(
        orderId: widget.orderId!,
        cfOrderId: widget.cfOrderId!,
        paymentSessionId: widget.paymentSessionId!,
      );
    } else {
      // ✅ No order data - need to create new order (Buy Now flow)
      debugPrint('📦 Creating new order');

      paymentVm.startPaymentProcess(
        userToken: widget.userToken,
        cartItems: widget.cartItems,
        singleProductId: null,
        singleQuantity: null,
        totalAmount: widget.totalAmount,
      );
    }
  }

  void _launchCashfree(String cfOrderId, String paymentSessionId) {
    try {
      cfPaymentGatewayService = CFPaymentGatewayService();
      cfPaymentGatewayService!.setCallback(_onPaymentSuccess, _onPaymentError);

      final cfSession =
          CFSessionBuilder()
              .setEnvironment(CFEnvironment.PRODUCTION)
              .setOrderId(cfOrderId)
              .setPaymentSessionId(paymentSessionId)
              .build();

      var cfDropCheckoutPayment =
          CFDropCheckoutPaymentBuilder().setSession(cfSession).build();

      cfPaymentGatewayService!.doPayment(cfDropCheckoutPayment);
    } on CFException catch (e) {
      debugPrint("CFException: ${e.message}");
    } catch (e) {
      debugPrint("Error launching Cashfree: $e");
    }
  }

  Future<void> _onPaymentSuccess(String orderId) async {
    _paymentCompleted = true;
    await ref
        .read(paymentViewModelProvider.notifier)
        .confirmPaymentOrder(userToken: widget.userToken, status: 'SUCCESS');

    if (!mounted) return;

    _showDialog(
      title: "Payment Successful",
      animationAsset: "assets/animations/Success animation.json",
      isSuccess: true,
    );
  }

  Future<void> _onPaymentError(CFErrorResponse error, String orderId) async {
    _paymentCompleted = true;
    await ref
        .read(paymentViewModelProvider.notifier)
        .confirmPaymentOrder(userToken: widget.userToken, status: 'FAILED');

    if (!mounted) return;

    _showDialog(
      title: "Payment Failed !!",
      animationAsset: "assets/animations/Warning.json",
      isSuccess: false,
    );
  }

  void _showDialog({
    required String title,
    required String animationAsset,
    required bool isSuccess,
  }) {
    final countdownNotifier = ref.read(countdownProvider.notifier);

    countdownNotifier.startCountdown(
      onComplete: () {
        Navigator.pop(context);
        ref.read(bottomNavProvider.notifier).setIndex(0);

        if (isSuccess) {
          Navigator.popUntil(context, (route) => route.isFirst);
        } else {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      },
    );

    showDialog(
      barrierColor: Colors.white,
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Consumer(
            builder: (context, ref, child) {
              final seconds = ref.watch(countdownProvider);

              return AlertDialog(
                backgroundColor: Colors.white,
                title: Text(title, style: const TextStyle(color: Colors.black)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Lottie.asset(
                      animationAsset,
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Redirecting in $seconds seconds...",
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}
