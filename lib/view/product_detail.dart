import 'package:cached_network_image/cached_network_image.dart';
import 'package:dd_grab/config/api_config.dart';
import 'package:dd_grab/service/payment_services.dart';
import 'package:dd_grab/view/address.dart';
import 'package:dd_grab/view/cart.dart';
import 'package:dd_grab/view/icon_badge.dart';
import 'package:dd_grab/view/purchase_method.dart';
import 'package:dd_grab/view/welcome.dart';
import 'package:dd_grab/viewmodels/cart_vm.dart';
import 'package:dd_grab/viewmodels/whislist_vm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:dd_grab/viewmodels/product_details_vm.dart';
import 'package:intl/intl.dart'; // For date formatting (add to pubspec.yaml if needed)

class ProductDetailsPage extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailsPage({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends ConsumerState<ProductDetailsPage> {
  final PageController _pageController = PageController(viewportFraction: 1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productDetailsProvider).fetchProductDetails(widget.productId);
    });
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return 'N/A';
    }
  }

  double _calculateDiscount(double price, double? specialPrice) {
    if (specialPrice == null || specialPrice >= price) return 0;
    return ((price - specialPrice) / price) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final productDetailsVm = ref.watch(productDetailsProvider);
    final theme = Theme.of(context);

    if (productDetailsVm.isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.yellow.shade600,
          surfaceTintColor: Colors.yellow.shade600,
        ),
        backgroundColor: Colors.white,
        body: _buildShimmerLoading(),
      );
    }

    if (productDetailsVm.errorMessage != null) {
      return Scaffold(
        body: Center(child: Text('Error: ${productDetailsVm.errorMessage}')),
      );
    }

    if (productDetailsVm.productDetails == null) {
      return const Scaffold(
        body: Center(child: Text('No product data found.')),
      );
    }

    final product = productDetailsVm.productDetails!['product'];
    final List<dynamic> relatedProducts =
        productDetailsVm.productDetails!['relatedProducts'] ?? [];

    final String productName = product['slug'] ?? 'Product Name';
    final dynamic sellingPriceValue = product['selling_price'];
    final double price =
        double.tryParse(sellingPriceValue?.toString() ?? '') ?? 0.0;
    final dynamic mrpValue = product['price'];
    final double mrp = double.tryParse(mrpValue?.toString() ?? '') ?? 0.0;
    final double specialPrice =
        double.tryParse(product['special_price']?.toString() ?? '') ?? 0.0;
    final double discount = _calculateDiscount(
      price,
      specialPrice > 0 ? specialPrice : null,
    );
    final bool isInStock = product['in_stock'] == 1;
    final int qty = product['qty'] ?? 0;
    final int viewed = product['viewed'] ?? 0;
    final String createdAt = _formatDate(product['created_at']);
    final String updatedAt = _formatDate(product['updated_at']);
    final String sku = product['sku'] ?? 'N/A';
    final isWishlisted = ref
        .watch(wishlistProvider)
        .wishlistedIds
        .contains(widget.productId);

    final cartState = ref.watch(cartViewModelProvider);
    final cartItemCount = cartState.cartItems.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow.shade600,
        surfaceTintColor: Colors.yellow.shade600,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconWithBadge(
              imagePath: 'assets/images/shopping-cart 1.png',
              count: cartItemCount,
              onTap: () async {
                final secureStorage = const FlutterSecureStorage();
                final token = await secureStorage.read(key: 'USER_TOKEN');

                if (token == null || token.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please login to continue'),
                      backgroundColor: Colors.black,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WelcomePage()),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CartPage()),
                );
              },
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Images Carousel
                  SizedBox(
                    height: 250,
                    child:
                        product['images']?.isEmpty ?? true
                            ? const Center(child: Text('No images available'))
                            : PageView.builder(
                              itemCount: product['images']?.length ?? 0,
                              controller: _pageController,
                              itemBuilder: (context, index) {
                                final imageItem = product['images'][index];
                                final imagePath =
                                    imageItem is Map<String, dynamic>
                                        ? imageItem['image'] ?? ''
                                        : imageItem?.toString() ?? '';

                                final imageUrl =
                                    ApiConfig.getImageUrl(imagePath);
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.contain,
                                    placeholder:
                                        (context, url) => Shimmer.fromColors(
                                          baseColor: Colors.grey.shade300,
                                          highlightColor: Colors.grey.shade100,
                                          child: Container(color: Colors.white),
                                        ),
                                    errorWidget:
                                        (context, url, error) => const Center(
                                          child: Icon(
                                            Icons.error_outline,
                                            color: Colors.red,
                                          ),
                                        ),
                                  ),
                                );
                              },
                            ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: SmoothPageIndicator(
                      controller: _pageController,
                      count: product['images']?.length ?? 0,
                      effect: const WormEffect(
                        dotHeight: 8,
                        dotWidth: 8,
                        activeDotColor: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Price and Stock Section
                  Row(
                    children: [
                      if (price > 0)
                        Text(
                          '₹${price.toStringAsFixed(0)}',
                          style: theme.textTheme.headlineSmall!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        const Text(
                          'Price unavailable',
                          style: TextStyle(color: Colors.red),
                        ),
                      const SizedBox(width: 8),
                      if (mrp > 0)
                        Text(
                          'M.R.P: ₹${mrp.toStringAsFixed(0)}',
                          style: theme.textTheme.bodyLarge!.copyWith(
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                  if (discount > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${discount.toStringAsFixed(0)}% off',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    (isInStock && qty > 0)
                        ? 'In Stock ($qty available)'
                        : 'Out of Stock',
                    style: TextStyle(
                      color: (isInStock && qty > 0) ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text('SKU: $sku'),
                  const SizedBox(height: 24),
                  Text(
                    'Product Info',
                    style: theme.textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Viewed by $viewed people'),
                  const SizedBox(height: 4),
                  Text('Created: $createdAt | Updated: $updatedAt'),
                  const SizedBox(height: 24),

                  // Delivery Section
                  Text(
                    'Delivery and Return Details',
                    style: theme.textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              maxLength: 6,
                              decoration: InputDecoration(
                                hintText: 'Pincode',
                                counterText: '', // Hide character counter
                                prefixIcon: const Icon(
                                  Icons.location_on_outlined,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color.fromARGB(255, 107, 105, 105),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color.fromARGB(255, 107, 105, 105),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color.fromARGB(255, 107, 105, 105),
                                  ),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                ref
                                    .read(productDetailsProvider)
                                    .setPincode(value);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed:
                                productDetailsVm.isPincodeLoading
                                    ? null
                                    : () {
                                      ref
                                          .read(productDetailsProvider)
                                          .checkPincode();
                                    },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child:
                                productDetailsVm.isPincodeLoading
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Text('Check'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Show success message
                      if (productDetailsVm.isPincodeValid == true)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Delivery available for pincode ${productDetailsVm.enteredPincode}',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Show error message
                      if (productDetailsVm.pincodeErrorMessage != null ||
                          productDetailsVm.isPincodeValid == false)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error,
                                color: Colors.red.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  productDetailsVm.pincodeErrorMessage ??
                                      'Delivery not available',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Related Products Section
                  if (relatedProducts.isNotEmpty) ...[
                    Text(
                      'Related Products',
                      style: theme.textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: relatedProducts.length,
                        itemBuilder: (context, index) {
                          final rp = relatedProducts[index];
                          final List<dynamic> images = rp['images'] ?? [];
                          if (images.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          // Safely extract image path
                          String imagePath = '';
                          final firstImage = images.first;

                          if (firstImage is String) {
                            imagePath = firstImage;
                          } else if (firstImage is Map<String, dynamic>) {
                            imagePath = firstImage['image']?.toString() ?? '';
                          }

                          // Skip invalid image entries
                          if (imagePath.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          // Create correct URL
                          final rpImageUrl =
                              imagePath.startsWith('http')
                                  ? imagePath
                                  : ApiConfig.getImageUrl(imagePath);

                          final rpName = rp['slug'] ?? 'Unnamed';
                          final rpPrice =
                              double.tryParse(
                                rp['selling_price']?.toString() ?? '',
                              ) ??
                              0.0;
                          return GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => ProductDetailsPage(
                                        productId: rp['id'].toString(),
                                      ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: CachedNetworkImage(
                                      imageUrl: rpImageUrl,
                                      fit: BoxFit.contain,
                                      placeholder:
                                          (context, url) => Shimmer.fromColors(
                                            baseColor: Colors.grey.shade300,
                                            highlightColor:
                                                Colors.grey.shade100,
                                            child: Container(
                                              color: Colors.white,
                                            ),
                                          ),
                                      errorWidget:
                                          (context, url, error) =>
                                              const Icon(Icons.broken_image),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      rpName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Text(
                                    rpPrice > 0
                                        ? '₹${rpPrice.toStringAsFixed(0)}'
                                        : 'N/A',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () async {
                    // Check authentication before toggling wishlist
                    final secureStorage = const FlutterSecureStorage();
                    final token = await secureStorage.read(key: 'USER_TOKEN');

                    if (token == null || token.isEmpty) {
                      // Guest user - show message and redirect to login
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('Please login to continue'),
                            backgroundColor: Colors.black,
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );

                      // Navigate to welcome/login page
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => WelcomePage()),
                      );
                      return;
                    }

                    // User is authenticated - proceed with wishlist toggle
                    final wasWishlisted = ref
                        .read(wishlistProvider)
                        .wishlistedIds
                        .contains(widget.productId);

                    await ref
                        .read(wishlistProvider.notifier)
                        .toggleWishlist(widget.productId);

                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(
                            wasWishlisted
                                ? 'Product removed from wishlist'
                                : 'Product added to wishlist',
                          ),
                          backgroundColor: Colors.black87,
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                  },
                  icon: Icon(
                    isWishlisted ? Icons.favorite : Icons.favorite_border,
                    color: isWishlisted ? Colors.red : Colors.black,
                  ),
                ),
              ),

              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final secureStorage = const FlutterSecureStorage();
                    final token = await secureStorage.read(key: 'USER_TOKEN');

                    if (token == null || token.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please login to continue'),
                          backgroundColor: Colors.black,
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => WelcomePage()),
                      );
                      return;
                    }

                    try {
                      final paymentService = PaymentService();
                      final orderData = await paymentService.initiateOrder(
                        userToken: token,
                        productId: int.parse(widget.productId),
                        quantity: 1,
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => PaymentScreen(
                                isBuyNow: true,
                                orderId: orderData['order_id'],
                                cfOrderId: orderData['cf_order_id'],
                                paymentSessionId:
                                    orderData['payment_session_id'],
                                totalAmount:
                                    double.tryParse(
                                      orderData['order_amount'].toString(),
                                    ) ??
                                    0,
                                userToken: token,
                              ),
                        ),
                      ).then((_) {
                        // ✅ Always refresh cart when payment screen closes
                        ref.read(cartViewModelProvider).fetchCart();
                      });
                    } on NoAddressException {
                      // ✅ Navigate directly to address page
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Add delivery address'),
                          backgroundColor: Colors.black,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 5),
                          action: SnackBarAction(
                            label: 'Add',
                            textColor: Colors.white,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddressPage(),
                                ),
                              ).then((_) {
                                ref.read(cartViewModelProvider).fetchCart();
                              });
                            },
                          ),
                        ),
                      );
                    } catch (e) {
                      ref.read(cartViewModelProvider).fetchCart();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Error: $e"),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.black, width: 1.5),
                    ),
                  ),
                  child: const Text('Buy Now'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    // Check authentication before adding to cart
                    final secureStorage = const FlutterSecureStorage();
                    final token = await secureStorage.read(key: 'USER_TOKEN');

                    if (token == null || token.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please login to continue'),
                          backgroundColor: Colors.black,
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => WelcomePage()),
                      );
                      return;
                    }

                    final cartVm = ref.read(cartViewModelProvider.notifier);

                    await cartVm.addToCart(
                      productId: widget.productId,
                      quantity: 1,
                    );

                    // Read latest state for error
                    final latestState = ref.read(cartViewModelProvider);
                    if (latestState.errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${latestState.errorMessage}'),
                        ),
                      );
                    } else {
                      // Refresh cart silently; ignore auth errors just in case
                      try {
                        await ref
                            .read(cartViewModelProvider.notifier)
                            .fetchCart();
                      } catch (_) {}

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Product added to cart!',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.black,
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Add to Bag'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image shimmer
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Product name shimmer
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 24,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 24,
                    width: 250,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Rating shimmer
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: 20,
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Price shimmer
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Row(
                children: [
                  Container(
                    height: 28,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 20,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Pincode check shimmer
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: 56,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Description shimmer
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 16,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
