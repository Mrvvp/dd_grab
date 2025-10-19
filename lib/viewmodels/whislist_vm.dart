import 'package:dd_grab/models/product_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WishlistState {
  final bool isLoading;
  final List<Product> items;
  final Set<String> wishlistedIds; // NEW: Track all wishlisted product IDs
  final String? errorMessage;
  final int currentPage;
  final int limit;
  final bool hasMore;

  WishlistState({
    this.isLoading = false,
    this.items = const [],
    this.wishlistedIds = const {}, // NEW
    this.errorMessage,
    this.currentPage = 1,
    this.limit = 20,
    this.hasMore = true,
  });

  WishlistState copyWith({
    bool? isLoading,
    List<Product>? items,
    Set<String>? wishlistedIds, // NEW
    String? errorMessage,
    int? currentPage,
    int? limit,
    bool? hasMore,
  }) {
    return WishlistState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      wishlistedIds: wishlistedIds ?? this.wishlistedIds, // NEW
      errorMessage: errorMessage,
      currentPage: currentPage ?? this.currentPage,
      limit: limit ?? this.limit,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// API base URL
const String baseUrl = 'https://dd-api.codesprint.cloud/api/v1';

// Flutter secure storage instance
final storage = FlutterSecureStorage();

// Provider for getting token asynchronously
final userTokenProvider = FutureProvider<String?>((ref) async {
  return await storage.read(key: 'USER_TOKEN');
});

// Wishlist state provider
final wishlistProvider =
    StateNotifierProvider<WishlistViewModel, WishlistState>(
      (ref) => WishlistViewModel(ref),
    );

class WishlistViewModel extends StateNotifier<WishlistState> {
  final Ref ref;
  WishlistViewModel(this.ref) : super(WishlistState());

  void syncWithProducts(List<Product> products) {
    final wishlistedIds =
        products
            .where((product) => product.isWishlisted)
            .map((product) => product.id)
            .toSet();

    // Update state with IDs from API response
    state = state.copyWith(wishlistedIds: wishlistedIds);

    print('🔄 Synced wishlist with ${wishlistedIds.length} products');
    print('Wishlisted IDs: $wishlistedIds');
  }

  Future<void> fetchWishlist({
    int page = 1,
    int limit = 20,
    bool preserveExistingIds = false,
  }) async {
    state = state.copyWith(isLoading: page == 1, errorMessage: null);

    try {
      final token = await ref.watch(userTokenProvider.future);
      final url = Uri.parse(
        '$baseUrl/product/wishlist?limit=$limit&page=$page',
      );
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        final List<dynamic> data =
            decoded is List ? decoded : (decoded['data'] as List<dynamic>);

        final products = data.map((e) => Product.fromJson(e)).toList();

        int returnedPage = page;
        int returnedLimit = limit;
        bool hasMore = true;
        if (decoded is Map && decoded.containsKey('meta')) {
          final meta = decoded['meta'];
          returnedPage = meta['current_page'] ?? page;
          final lastPage = meta['last_page'];
          hasMore =
              lastPage == null
                  ? products.length == limit
                  : (returnedPage < lastPage);
        } else {
          hasMore = products.length >= limit;
        }

        final allItems = page == 1 ? products : [...state.items, ...products];

        // Build set of IDs from fetched items
        final fetchedIds = allItems.map((p) => p.id.toString()).toSet();

        // Merge with existing IDs if preserving
        final allWishlistedIds =
            preserveExistingIds
                ? {...state.wishlistedIds, ...fetchedIds}
                : fetchedIds;

        state = state.copyWith(
          isLoading: false,
          items: allItems,
          wishlistedIds: allWishlistedIds,
          currentPage: returnedPage,
          limit: returnedLimit,
          hasMore: hasMore,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load wishlist (${response.statusCode})',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> toggleWishlist(String productId) async {
    final token = await ref.watch(userTokenProvider.future);

    try {
      final url = Uri.parse('$baseUrl/product/toggle-wishlist/$productId');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true) {
          final action = body['data']['action'];

          Set<String> updatedWishlistedIds = Set.from(state.wishlistedIds);

          if (action == 'added') {
            updatedWishlistedIds.add(productId);
          } else if (action == 'removed') {
            updatedWishlistedIds.remove(productId);
          }

          state = state.copyWith(wishlistedIds: updatedWishlistedIds);

          // Refresh items in background, preserve manually toggled IDs
          fetchWishlist(page: 1, limit: state.limit, preserveExistingIds: true);
        } else {
          final msg = body['message'] ?? 'Failed to toggle wishlist';
          state = state.copyWith(errorMessage: msg);
          throw Exception(msg);
        }
      } else {
        final msg = 'Failed to toggle wishlist (${response.statusCode})';
        state = state.copyWith(errorMessage: msg);
        throw Exception(msg);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> loadMoreWishlist() async {
    if (!state.hasMore || state.isLoading) return;
    final nextPage = state.currentPage + 1;
    await fetchWishlist(page: nextPage, limit: state.limit);
  }
}
