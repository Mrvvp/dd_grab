import 'package:cached_network_image/cached_network_image.dart';
import 'package:dd_grab/models/product_model.dart';
import 'package:dd_grab/view/product_detail.dart';
import 'package:dd_grab/view/reusable_appbar.dart';
import 'package:dd_grab/viewmodels/cart_vm.dart';
import 'package:dd_grab/viewmodels/whislist_vm.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shimmer/shimmer.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({Key? key}) : super(key: key);

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);

    // Fetch wishlist when page opens
    Future.microtask(() async {
      final secureStorage = const FlutterSecureStorage();
      final token = await secureStorage.read(key: 'USER_TOKEN');

      if (token == null || token.isEmpty) {
        // Guest user - show message only
        if (mounted) {}
        return;
      }

      // User is authenticated - fetch wishlist
      final container = ProviderScope.containerOf(context);
      container.read(wishlistProvider.notifier).fetchWishlist();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Near bottom, load more
      final container = ProviderScope.containerOf(context);
      container.read(wishlistProvider.notifier).loadMoreWishlist();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final wishlistState = ref.watch(wishlistProvider);

        if (wishlistState.isLoading && wishlistState.items.isEmpty) {
          return const Scaffold(
            body: CircularProgressIndicator(color: Colors.black),
          );
        }
        if (wishlistState.errorMessage != null && wishlistState.items.isEmpty) {
          return Scaffold(
            body: Column(
              children: [
                CustomHomeAppBar(),
                Text('Error: ${wishlistState.errorMessage}'),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              CustomHomeAppBar(),
              Expanded(
                child:
                    wishlistState.items.isEmpty
                        ? const Center(child: Text('Your wishlist is empty'))
                        : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: GridView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisExtent: 340,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            itemCount:
                                wishlistState.items.length +
                                (wishlistState.hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == wishlistState.items.length) {
                                return CircularProgressIndicator(
                                  color: Colors.black,
                                );
                              }
                              final item = wishlistState.items[index];
                              return _WishlistTile(
                                product: item,
                                onDelete: () async {
                                  await ref
                                      .read(wishlistProvider.notifier)
                                      .toggleWishlist(item.id);
                                },
                              );
                            },
                          ),
                        ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WishlistTile extends ConsumerWidget {
  const _WishlistTile({required this.product, required this.onDelete});
  final Product product;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(productId: product.id),
          ),
        );
      },
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // ✅ ADDED THIS
          children: [
            // Image section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: SizedBox(
                    height: 150, // ✅ Fixed height instead of AspectRatio
                    width: double.infinity,
                    child:
                        product.image.isNotEmpty
                            ? CachedNetworkImage(
                              imageUrl: product.image,
                              fit: BoxFit.cover,
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
                            )
                            : Icon(Icons.error_outline, color: Colors.red),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Product name
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

            // Rating
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

            // Price
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
                  Flexible(
                    child: Text(
                      'M.R.P. ₹${product.mrp.toStringAsFixed(0)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall!.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8), // ✅ Small spacer
            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(CupertinoIcons.delete, size: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final cartVm = ref.read(cartViewModelProvider.notifier);
                        await cartVm.addToCart(
                          productId: product.id.toString(),
                          quantity: 1,
                        );
                        final latestState = ref.read(cartViewModelProvider);
                        if (latestState.errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error: ${latestState.errorMessage}',
                              ),
                            ),
                          );
                        } else {
                          await cartVm.fetchCart();
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
                      icon: Image.asset(
                        'assets/images/shopping-cart 1.png',
                        width: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Add to Bag',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        minimumSize: const Size(0, 32),
                      ),
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
