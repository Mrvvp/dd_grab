import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dd_grab/models/product_model.dart';
import 'package:dd_grab/view/cart.dart';
import 'package:dd_grab/view/icon_badge.dart';
import 'package:dd_grab/view/product_detail.dart';
import 'package:dd_grab/view/welcome.dart';
import 'package:dd_grab/viewmodels/cart_vm.dart';
import 'package:dd_grab/viewmodels/product_vm.dart';
import 'package:dd_grab/viewmodels/whislist_vm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shimmer/shimmer.dart';

class ProductListPage extends ConsumerStatefulWidget {
  const ProductListPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.apiUrl,
    this.isDeals = false,
    this.isRecommended = false,
  });
  final String categoryId;
  final String categoryName;
  final String apiUrl;
  final bool isDeals;
  final bool isRecommended;

  @override
  ConsumerState<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends ConsumerState<ProductListPage> {
  late ScrollController _scrollController;
  Timer? _scrollDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productVM = ref.read(productListProvider.notifier);
      final wishlistVM = ref.read(wishlistProvider.notifier);

      productVM.onProductsLoaded = (products) {
        wishlistVM.syncWithProducts(products);
      };

      if (widget.categoryId.isNotEmpty) {
        // Category/Subcategory flow
        productVM.fetchProductsByCategory(widget.categoryId);
      } else if (widget.isDeals) {
        // Today's deals flow
        productVM.fetchProductsFromApi(widget.apiUrl, isDeal: true);
      } else if (widget.isRecommended) {
        // Recommended products flow
        productVM.fetchProductsFromApi(widget.apiUrl, isDeal: false);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // ✅ Cancel previous timer
      _scrollDebounce?.cancel();

      // ✅ Set new timer - only trigger after 300ms of no scrolling
      _scrollDebounce = Timer(const Duration(milliseconds: 300), () {
        final productVM = ref.read(productListProvider.notifier);
        final productState = ref.read(productListProvider);

        if (widget.categoryId.isNotEmpty) {
          if (!productState.isLoadingProducts && productState.hasMoreProducts) {
            productVM.loadMoreProducts();
          }
        } else if (widget.isDeals) {
          if (!productState.isLoadingDeals && productState.hasMoreDeals) {
            productVM.loadMoreDeals(widget.apiUrl);
          }
        } else if (widget.isRecommended) {
          if (!productState.isLoadingRecommended &&
              productState.hasMoreRecommended) {
            productVM.loadMoreRecommended(widget.apiUrl);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.read(productListProvider.notifier);
    final productListState = ref.watch(productListProvider);
    final cartState = ref.watch(cartViewModelProvider);
    final cartItemCount = cartState.cartItems.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
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
      body: Container(
        decoration: const BoxDecoration(),
        child: Column(
          children: [
            SizedBox(height: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Builder(
                  builder: (_) {
                    final isLoading =
                        widget.categoryId.isNotEmpty
                            ? productListState.isLoadingProducts
                            : widget.isDeals
                            ? productListState.isLoadingDeals
                            : productListState.isLoadingRecommended;

                    final errorMessage =
                        widget.categoryId.isNotEmpty
                            ? productListState.errorProducts
                            : widget.isDeals
                            ? productListState.errorDeals
                            : productListState.errorRecommended;

                    final productsList =
                        widget.categoryId.isNotEmpty
                            ? productListState.products
                            : widget.isDeals
                            ? productListState.todaysDeals
                            : productListState.recommended;

                    final hasMore =
                        widget.categoryId.isNotEmpty
                            ? productListState.hasMoreProducts
                            : widget.isDeals
                            ? productListState.hasMoreDeals
                            : productListState.hasMoreRecommended;

                    if (isLoading && productsList.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.black),
                      );
                    } else if (errorMessage != null) {
                      return Center(child: Text('Error: $errorMessage'));
                    } else if (productsList.isEmpty) {
                      return const Center(
                        child: Text('No products available.'),
                      );
                    } else {
                      return GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(bottom: 80),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisExtent: 260,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount:
                            productsList.length +
                            (hasMore && isLoading ? 2 : 0),
                        itemBuilder: (_, i) {
                          if (i >= productsList.length) {
                            return const CircularProgressIndicator(
                              color: Colors.black,
                            );
                          }
                          // Return product tile for valid indices
                          return _ProductTile(product: productsList[i]);
                        },
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: _SortFilterBar(
          isDeals: widget.isDeals,
          isRecommended: widget.isRecommended,
        ),
      ),
    );
  }
}

class _ProductTile extends ConsumerWidget {
  const _ProductTile({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    bool isToggling = false;

    final wishlistState = ref.watch(wishlistProvider);
    final isWishlisted = wishlistState.wishlistedIds.contains(
      product.id.toString(),
    );

    print('Product ${product.id} isWishlisted: $isWishlisted');
    print('All wishlisted IDs: ${wishlistState.wishlistedIds}');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          print('Tapped Product ID: ${product.id}');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsPage(productId: product.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: CachedNetworkImage(
                      imageUrl: product.image,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: SizedBox(
                              height: 150,
                              width: double.infinity,
                              child: Container(color: Colors.white),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => const Center(
                            child: Icon(Icons.error_outline, color: Colors.red),
                          ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    width: 40,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: GestureDetector(
                      onTap: () async {
                        if (isToggling)
                          return; // prevent repeated taps while processing

                        // Check authentication before toggling wishlist
                        final secureStorage = const FlutterSecureStorage();
                        final token = await secureStorage.read(
                          key: 'USER_TOKEN',
                        );

                        if (token == null || token.isEmpty) {
                          // Guest user - show message and redirect to login
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please login to continue',
                                  style: TextStyle(fontSize: 14),
                                ),
                                duration: Duration(seconds: 2),
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
                              ),
                            );

                          // Navigate to welcome/login page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WelcomePage(),
                            ),
                          );
                          return;
                        }

                        // User is authenticated - proceed with wishlist toggle
                        isToggling = true;

                        final isCurrentlyWishlisted = isWishlisted;
                        try {
                          // ✅ Toggle wishlist on backend
                          await ref
                              .read(wishlistProvider.notifier)
                              .toggleWishlist(product.id);

                          // ✅ NEW: Update product list to reflect the change
                          ref
                              .read(productListProvider.notifier)
                              .updateProductWishlistStatus(
                                product.id,
                                !isCurrentlyWishlisted, // New status
                              );

                          // Show success snackbar
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  isCurrentlyWishlisted
                                      ? "Product removed from wishlist"
                                      : "Product added to wishlist",
                                  style: const TextStyle(fontSize: 14),
                                ),
                                duration: const Duration(seconds: 2),
                                backgroundColor: Colors.black87,
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                        } catch (e) {
                          // ✅ NEW: Revert the product list update on error
                          ref
                              .read(productListProvider.notifier)
                              .updateProductWishlistStatus(
                                product.id,
                                isCurrentlyWishlisted, // Revert to original status
                              );

                          // Show error snackbar on failure
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to update wishlist: $e',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                duration: const Duration(seconds: 2),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                        } finally {
                          isToggling = false;
                        }
                      },
                      child: Icon(
                        isWishlisted ? Icons.favorite : Icons.favorite_border,
                        color: isWishlisted ? Colors.red : Colors.black,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 14),
                  const SizedBox(width: 2),
                  Text(
                    product.rating.toStringAsFixed(1),
                    style: theme.textTheme.bodySmall!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${product.ratingCount})',
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '₹${product.price.toStringAsFixed(0)}',
                    style: theme.textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'M.R.P. ₹${product.mrp.toStringAsFixed(0)}',
                    style: theme.textTheme.bodySmall!.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
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

class _SortFilterBar extends ConsumerStatefulWidget {
  final bool isDeals; // NEW: pass whether this is deals or category page
  final bool isRecommended;
  const _SortFilterBar({this.isDeals = false, this.isRecommended = false});

  @override
  ConsumerState<_SortFilterBar> createState() => _SortFilterBarState();
}

class _SortFilterBarState extends ConsumerState<_SortFilterBar> {
  String selectedSort = '';

  static const Map<String, String> priceSortOrder = {
    'Price - high to low': 'desc',
    'Price - low to high': 'asc',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder:
                    (_) => SortBottomSheet(
                      selectedOption: selectedSort,
                      onOptionSelected: (String option) {
                        setState(() {
                          selectedSort = option;
                        });

                        final sortOrder =
                            _SortFilterBarState.priceSortOrder[option]!;

                        // Use the flag passed from parent
                        ref
                            .read(productListProvider.notifier)
                            .sortProducts(
                              sortOrder: sortOrder,
                              isDeals: widget.isDeals,
                              isRecommended: widget.isRecommended,
                            );
                      },
                    ),
              );
            },
            child: Row(
              children: const [
                Icon(Icons.sort, size: 20),
                SizedBox(width: 6),
                Text('Sort By', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SortBottomSheet extends StatelessWidget {
  final String selectedOption;
  final Function(String) onOptionSelected;

  const SortBottomSheet({
    Key? key,
    required this.selectedOption,
    required this.onOptionSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final options = ['Price - high to low', 'Price - low to high'];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sort By',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          ...options.map(
            (opt) => Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    opt,
                    style: TextStyle(
                      fontWeight:
                          selectedOption == opt
                              ? FontWeight.bold
                              : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () {
                    onOptionSelected(opt);
                    Navigator.pop(context);
                  },
                ),
                if (opt != options.last)
                  Divider(color: Colors.grey.shade300, height: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
