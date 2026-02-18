import 'package:cached_network_image/cached_network_image.dart';
import 'package:dd_grab/config/api_config.dart';
import 'package:dd_grab/service/payment_services.dart';
import 'package:dd_grab/view/address.dart';
import 'package:dd_grab/view/product_detail.dart';
import 'package:dd_grab/view/purchase_method.dart';
import 'package:dd_grab/viewmodels/address_vm.dart';
import 'package:dd_grab/viewmodels/cart_vm.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shimmer/shimmer.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  final TextEditingController _walletController = TextEditingController();
  bool _agreeToTerms = false;

  @override
  void initState() {
    super.initState();
    _refreshCart();
    _walletController.addListener(_onWalletAmountChanged);
  }

  @override
  void dispose() {
    _walletController.dispose();
    super.dispose();
  }

  void _onWalletAmountChanged() {
    final vm = ref.read(cartViewModelProvider);
    if (_walletController.text.isNotEmpty && vm.useWallet) {
      final amount = double.tryParse(_walletController.text) ?? 0.0;
      vm.updateWalletAmount(amount);
    } else if (_walletController.text.isEmpty && vm.useWallet) {
      vm.updateWalletAmount(0.0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ Reload cart every time page becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshCart();
      }
    });
  }

  void _refreshCart() {
    Future.microtask(() {
      ref.read(cartViewModelProvider).fetchCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(cartViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),
        backgroundColor: Colors.yellow.shade600,
        surfaceTintColor: Colors.yellow.shade600,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child:
                  vm.isLoading
                      ? _buildShimmerLoading()
                      : vm.errorMessage != null
                      ? Center(child: Text("Error: ${vm.errorMessage}"))
                      : vm.cartItems.isEmpty
                      ? const Center(child: Text("Your cart is empty."))
                      : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Bag (${vm.cartItems.length} Product${vm.cartItems.length > 1 ? 's' : ''})",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...vm.cartItems.map(
                              (item) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: _CartItemCard(
                                  ref: ref,
                                  item: item,
                                  onQuantityChanged: (newQty) {
                                    ref
                                        .read(cartViewModelProvider)
                                        .updateCartItemQuantity(
                                          item['id'],
                                          newQty,
                                        );
                                  },
                                  onRemove: () {
                                    final productId = item['id']?.toString();
                                    if (productId != null &&
                                        productId != 'null') {
                                      ref
                                          .read(cartViewModelProvider)
                                          .removeCartItem(productId);
                                    } else {
                                      debugPrint(
                                        '❌ Error: product_id is null or invalid',
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            //   children: [
                            //     const Row(
                            //       children: [
                            //         Icon(Icons.discount),
                            //         SizedBox(width: 6),
                            //         Text("Apply coupon"),
                            //       ],
                            //     ),
                            //     TextButton(
                            //       onPressed: () {},
                            //       child: const Text("Select"),
                            //     ),
                            //   ],
                            // ),
                            const Divider(height: 32),
                            // Wallet Section
                            _WalletSection(
                              ref: ref,
                              walletController: _walletController,
                            ),
                            const Divider(height: 32),
                            const Text(
                              "Order Payment Details",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            _DetailRow(
                              label: "Order Amount",
                              value: "₹${vm.subtotalAmount.toStringAsFixed(2)}",
                            ),
                            if (vm.useWallet && vm.walletAmount > 0) ...[
                              const SizedBox(height: 6),
                              _DetailRow(
                                label: "Wallet Discount",
                                value:
                                    "-₹${vm.walletAmount.toStringAsFixed(2)}",
                                valueColor: Colors.green,
                              ),
                            ],
                            const SizedBox(height: 6),
                            _DetailRow(
                              label: "Order Total",
                              value: "₹${vm.totalAmount.toStringAsFixed(2)}",
                              isBold: true,
                            ),
                            const SizedBox(height: 24),
                            // Terms and Conditions Checkbox
                            Row(
                              children: [
                                Checkbox(
                                  value: _agreeToTerms,
                                  fillColor: WidgetStateProperty.resolveWith<
                                    Color
                                  >((Set<WidgetState> states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return Colors.black;
                                    }
                                    return Colors.transparent;
                                  }),
                                  checkColor: Colors.white,
                                  side: const BorderSide(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _agreeToTerms = value ?? false;
                                    });
                                  },
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _agreeToTerms = !_agreeToTerms;
                                      });
                                    },
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black,
                                        ),
                                        children: [
                                          const TextSpan(
                                            text: "I agree to the ",
                                          ),
                                          TextSpan(
                                            text: "Terms & Conditions",
                                            style: const TextStyle(
                                              decoration:
                                                  TextDecoration.underline,
                                              color: Colors.black,
                                            ),
                                            recognizer:
                                                TapGestureRecognizer()
                                                  ..onTap = () {
                                                    // Show terms and conditions dialog
                                                    showDialog(
                                                      context: context,
                                                      builder:
                                                          (
                                                            context,
                                                          ) => AlertDialog(
                                                            title: const Text(
                                                              "Terms & Conditions",
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            content: const SingleChildScrollView(
                                                              child: Text(
                                                                "Please read and accept our Terms & Conditions to proceed with your order.",
                                                                style:
                                                                    TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                    ),
                                                              ),
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () {
                                                                  Navigator.pop(
                                                                    context,
                                                                  );
                                                                },
                                                                child:
                                                                    const Text(
                                                                      "Close",
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                    );
                                                  },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
            ),
            if (vm.cartItems.isNotEmpty)
              _BottomBar(vm: vm, agreeToTerms: _agreeToTerms),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 16,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Cart items shimmer (3 items)
          ...List.generate(3, (index) => _ShimmerCartItem()),

          const SizedBox(height: 24),
          const Divider(height: 32),

          // Order payment details shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 14,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      height: 14,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 14,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      height: 14,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;
  final WidgetRef ref;

  const _CartItemCard({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final product = item;

    final double sellingPrice =
        double.tryParse(item['selling_price']?.toString() ?? '') ?? 0;
    final double mrp = double.tryParse(product['mrp']?.toString() ?? '') ?? 0;

    return GestureDetector(
      onTap: () {
        final productId = item['id'].toString();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(productId: productId),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildProductImage(item),
            ),

            const SizedBox(width: 12),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Delete icon
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product['slug'] ?? 'Product Name',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 5),
                      GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(CupertinoIcons.delete, size: 14),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Quantity dropdown
                  DropdownButton<int>(
                    underline: const SizedBox.shrink(),
                    value:
                        (item['quantity'] is int)
                            ? item['quantity'] as int
                            : int.tryParse(
                                  item['quantity']?.toString() ?? '1',
                                ) ??
                                1,
                    isDense: true,
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                    items: List.generate(5, (index) {
                      final qty = index + 1;
                      return DropdownMenuItem<int>(
                        value: qty,
                        child: Text("QTY $qty"),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        onQuantityChanged(value);
                      }
                    },
                  ),

                  const SizedBox(height: 6),

                  // Price
                  Row(
                    children: [
                      Text(
                        "₹${sellingPrice.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "M.R.P. ₹${mrp.toStringAsFixed(2)}",
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Add this method inside _CartItemCard class
  Widget _buildProductImage(Map<String, dynamic> item) {
    // Check if images exist and are not empty
    final images = item['images'];

    if (images == null || (images is List && images.isEmpty)) {
      // Show placeholder if no images
      return Container(
        width: 110,
        height: 70,
        color: Colors.grey[200],
        child: Icon(
          Icons.image_not_supported,
          size: 40,
          color: Colors.grey[400],
        ),
      );
    }

    // Get first image
    final firstImage = (images is List) ? images.first : images.toString();

    return CachedNetworkImage(
      imageUrl: ApiConfig.getImageUrl(firstImage.toString()),
      width: 110,
      height: 70,
      fit: BoxFit.cover,
      placeholder:
          (context, url) => Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(width: 110, height: 70, color: Colors.white),
          ),
      errorWidget:
          (context, url, error) => Container(
            width: 110,
            height: 70,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, size: 40),
          ),
    );
  }
}

class _WalletSection extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final TextEditingController walletController;

  const _WalletSection({required this.ref, required this.walletController});

  @override
  ConsumerState<_WalletSection> createState() => _WalletSectionState();
}

class _WalletSectionState extends ConsumerState<_WalletSection> {
  @override
  void initState() {
    super.initState();
    // Sync controller with view model when wallet is enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = widget.ref.read(cartViewModelProvider);
      if (vm.useWallet && vm.walletAmount > 0) {
        widget.walletController.text = vm.walletAmount.toStringAsFixed(2);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(cartViewModelProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Checkbox for wallet usage
        Row(
          children: [
            Checkbox(
              value: vm.useWallet,
              fillColor: WidgetStateProperty.resolveWith<Color>((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.black;
                }
                return Colors.transparent;
              }),
              checkColor: Colors.white,
              side: const BorderSide(color: Colors.black, width: 2),
              onChanged: (value) {
                final cartVm = ref.read(cartViewModelProvider);
                cartVm.toggleWalletUsage();
                if (cartVm.useWallet) {
                  // Set suggested amount when enabling
                  final suggestedAmount =
                      cartVm.totalUsableWallet < cartVm.totalBeforeWallet
                          ? cartVm.totalUsableWallet
                          : cartVm.totalBeforeWallet;
                  widget.walletController.text = suggestedAmount
                      .toStringAsFixed(2);
                  cartVm.updateWalletAmount(suggestedAmount);
                } else {
                  widget.walletController.clear();
                }
              },
            ),
            const Expanded(
              child: Text(
                "Do you want to use your wallet amount?",
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
            ),
          ],
        ),

        // Show wallet details when checkbox is checked
        if (vm.useWallet) ...[
          const SizedBox(height: 12),
          if (vm.isWalletLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            // Total Active Wallet
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Active Wallet:",
                    style: TextStyle(fontSize: 13, color: Colors.black),
                  ),
                  Text(
                    "₹${vm.totalActiveWallet.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // Total Usable Wallet
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Usable Wallet:",
                    style: TextStyle(fontSize: 13, color: Colors.black),
                  ),
                  Text(
                    "₹${vm.totalUsableWallet.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // Enter Amount input field with Apply button
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.walletController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: "Enter Amount",
                        labelStyle: const TextStyle(color: Colors.black),
                        hintText: "0.00",
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixText: "₹",
                        prefixStyle: const TextStyle(color: Colors.black),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        final amount = double.tryParse(value) ?? 0.0;
                        ref
                            .read(cartViewModelProvider)
                            .updateWalletAmount(amount);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed:
                        vm.isWalletLoading
                            ? null
                            : () async {
                              final cartVm = ref.read(cartViewModelProvider);
                              final success = await cartVm.applyWalletAmount();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Wallet amount applied successfully!'
                                          : cartVm.walletErrorMessage ??
                                              'Failed to apply wallet amount',
                                    ),
                                    backgroundColor:
                                        success ? Colors.green : Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        vm.isWalletLoading
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text(
                              "Apply",
                              style: TextStyle(color: Colors.white),
                            ),
                  ),
                ],
              ),
            ),

            // Error message if any
            if (vm.walletErrorMessage != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(
                  vm.walletErrorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ],
          ],
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _BottomBar extends ConsumerStatefulWidget {
  final CartViewModel vm;
  final bool agreeToTerms;

  const _BottomBar({required this.vm, required this.agreeToTerms});

  @override
  ConsumerState<_BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends ConsumerState<_BottomBar> {
  bool _isProcessing = false; // ✅ Track button loading state

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "₹${widget.vm.totalAmount.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed:
                widget.vm.cartItems.isEmpty ||
                        _isProcessing ||
                        !widget.agreeToTerms
                    ? null
                    : () => _proceedToPayment(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ✅ Text always takes space (invisible when loading)
                Visibility(
                  visible: !_isProcessing,
                  maintainSize: true, // ✅ This keeps the space reserved
                  maintainAnimation: true,
                  maintainState: true,
                  child: const Text(
                    "Proceed to Payment",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                if (_isProcessing)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _proceedToPayment(BuildContext context) async {
    // Check if terms are agreed
    if (!widget.agreeToTerms) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please agree to Terms & Conditions to continue'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final secureStorage = const FlutterSecureStorage();
    final token = await secureStorage.read(key: 'USER_TOKEN');

    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to continue'),
            backgroundColor: Colors.black,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // ✅ Get ref BEFORE any async operations
    final addressNotifier = ref.read(addressViewModelProvider.notifier);

    if (!mounted) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // ✅ DON'T FETCH CART - Just check current state
      debugPrint('🛒 Checking cart items...');
      debugPrint('🛒 Cart items count: ${widget.vm.cartItems.length}');

      // ✅ CHECK IF CART IS EMPTY
      if (widget.vm.cartItems.isEmpty) {
        debugPrint('⚠️ Cart is empty');

        if (!mounted) return;

        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your cart is empty. Please add items to continue.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      debugPrint('📍 Fetching addresses...');

      // ✅ Fetch addresses
      await addressNotifier.fetchAddresses(forceRefresh: true);

      if (!mounted) {
        debugPrint('❌ Widget unmounted after address fetch');
        return;
      }

      final addressState = ref.read(addressViewModelProvider);
      debugPrint('📍 Address count: ${addressState.addresses.length}');

      // ✅ CHECK IF THERE ARE NO ADDRESSES - SHOW SNACKBAR WITH ACTION
      if (addressState.addresses.isEmpty) {
        debugPrint('⚠️ No addresses found - showing snackbar with action');

        if (!mounted) return;

        setState(() {
          _isProcessing = false;
        });

        // ✅ SNACKBAR WITH ACTION BUTTON FOR NAVIGATION
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Add delivery address'),
            backgroundColor: Colors.black,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Add',
              textColor: Colors.white,
              onPressed: () async {
                debugPrint(
                  '🚀 Navigating to AddressPage from SnackBar action...',
                );

                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddressPage()),
                );

                debugPrint('✅ Returned from AddressPage with result: $result');

                // ✅ Check if user added an address
                if (result != null && result == true && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Address added! Click proceed to continue.',
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ),
        );
        return;
      }

      debugPrint('✅ Cart and address validation passed - initiating payment');

      if (!mounted) return;

      // ✅ Initiate payment only if cart has items and address exists
      final paymentService = PaymentService();
      final orderData = await paymentService.initiateOrder(userToken: token);

      if (!mounted) return;

      debugPrint('✅ Payment initiated successfully');

      setState(() {
        _isProcessing = false;
      });

      // ✅ Navigate to payment screen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => PaymentScreen(
                isBuyNow: false,
                orderId: orderData['order_id'],
                cfOrderId: orderData['cf_order_id'],
                paymentSessionId: orderData['payment_session_id'],
                totalAmount:
                    double.tryParse(orderData['order_amount'].toString()) ??
                    widget.vm.totalAmount,
                userToken: token,
                cartItems: widget.vm.cartItems,
              ),
        ),
      );

      if (!mounted) return;

      // ✅ Refresh cart after payment screen closes (this is OK because user is back)
      await widget.vm.fetchCart();
    } on NoAddressException {
      debugPrint('⚠️ NoAddressException caught');

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      // ✅ SNACKBAR WITH ACTION BUTTON FOR NAVIGATION
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Add anaddress to continue'),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Add Address',
            textColor: Colors.white,
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddressPage()),
              );

              if (result != null && result == true && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Address added! Click proceed to continue.'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ),
      );
    } on EmptyCartException catch (e) {
      debugPrint('⚠️ EmptyCartException: ${e.message}');

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error in payment process: $e');

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

class _ShimmerCartItem extends StatelessWidget {
  const _ShimmerCartItem();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: 110,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Product details shimmer
          Expanded(
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 12,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 12,
                              width: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 30,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        height: 13,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 11,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
