// lib/providers/product_list_provider.dart

import 'dart:convert';
import 'package:dd_grab/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

@immutable
class ProductListState {
  const ProductListState({
    this.products = const [],
    this.todaysDeals = const [],
    this.recommended = const [],
    this.isLoadingProducts = false,
    this.isLoadingDeals = false,
    this.isLoadingRecommended = false,
    this.errorProducts,
    this.errorDeals,
    this.errorRecommended,
    this.currentPageProducts = 1,
    this.currentPageDeals = 1,
    this.currentPageRecommended = 1,
    this.hasMoreProducts = true,
    this.hasMoreDeals = true,
    this.hasMoreRecommended = true,
  });

  final List<Product> products;
  final List<Product> todaysDeals;
  final List<Product> recommended;

  final bool isLoadingProducts;
  final bool isLoadingDeals;
  final bool isLoadingRecommended;

  final String? errorProducts;
  final String? errorDeals;
  final String? errorRecommended;

  // Pagination fields
  final int currentPageProducts;
  final int currentPageDeals;
  final int currentPageRecommended;

  final bool hasMoreProducts;
  final bool hasMoreDeals;
  final bool hasMoreRecommended;

  ProductListState copyWith({
    List<Product>? products,
    List<Product>? todaysDeals,
    List<Product>? recommended,
    bool? isLoadingProducts,
    bool? isLoadingDeals,
    bool? isLoadingRecommended,
    String? errorProducts,
    String? errorDeals,
    String? errorRecommended,
    int? currentPageProducts,
    int? currentPageDeals,
    int? currentPageRecommended,
    bool? hasMoreProducts,
    bool? hasMoreDeals,
    bool? hasMoreRecommended,
  }) {
    return ProductListState(
      products: products ?? this.products,
      todaysDeals: todaysDeals ?? this.todaysDeals,
      recommended: recommended ?? this.recommended,
      isLoadingProducts: isLoadingProducts ?? this.isLoadingProducts,
      isLoadingDeals: isLoadingDeals ?? this.isLoadingDeals,
      isLoadingRecommended: isLoadingRecommended ?? this.isLoadingRecommended,
      errorProducts: errorProducts ?? this.errorProducts,
      errorDeals: errorDeals ?? this.errorDeals,
      errorRecommended: errorRecommended ?? this.errorRecommended,
      currentPageProducts: currentPageProducts ?? this.currentPageProducts,
      currentPageDeals: currentPageDeals ?? this.currentPageDeals,
      currentPageRecommended:
          currentPageRecommended ?? this.currentPageRecommended,
      hasMoreProducts: hasMoreProducts ?? this.hasMoreProducts,
      hasMoreDeals: hasMoreDeals ?? this.hasMoreDeals,
      hasMoreRecommended: hasMoreRecommended ?? this.hasMoreRecommended,
    );
  }
}

final productListProvider =
    StateNotifierProvider<ProductListVM, ProductListState>(
      (ref) => ProductListVM(),
    );

class ProductListVM extends StateNotifier<ProductListState> {
  ProductListVM()
    : super(
        const ProductListState(
          products: [],
          todaysDeals: [],
          recommended: [],
          isLoadingProducts: true,
        ),
      );

  bool isDealsActive = false;
  bool isRecommendedActive = false;
  String? lastCategoryId; // Track current category

  Function(List<Product>)? onProductsLoaded;

  // Add to ProductListVM class
  void updateProductWishlistStatus(String productId, bool isWishlisted) {
    // Update in products list
    final updatedProducts =
        state.products.map((product) {
          if (product.id == productId) {
            return product.copyWith(isWishlisted: isWishlisted);
          }
          return product;
        }).toList();

    // Update in deals list
    final updatedDeals =
        state.todaysDeals.map((product) {
          if (product.id == productId) {
            return product.copyWith(isWishlisted: isWishlisted);
          }
          return product;
        }).toList();

    // Update in recommended list
    final updatedRecommended =
        state.recommended.map((product) {
          if (product.id == productId) {
            return product.copyWith(isWishlisted: isWishlisted);
          }
          return product;
        }).toList();

    state = state.copyWith(
      products: updatedProducts,
      todaysDeals: updatedDeals,
      recommended: updatedRecommended,
    );

    print('✅ Updated product $productId wishlist status to $isWishlisted');
  }

  Future<void> fetchProductsByCategory(
    String categoryId, {
    int page = 1,
    int limit = 20,
  }) async {
    print(
      'DEBUG: fetchProductsByCategory called with categoryId: $categoryId, page: $page',
    );

    // Reset if new category
    if (lastCategoryId != categoryId) {
      lastCategoryId = categoryId;
      state = state.copyWith(
        products: [],
        currentPageProducts: 1,
        hasMoreProducts: true,
      );
    }

    state = state.copyWith(isLoadingProducts: page == 1, errorProducts: null);

    try {
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'USER_TOKEN');
      final url =
          '${ApiConfig.productCategory}/$categoryId?page=$page&limit=$limit';
      print('DEBUG: API URL: $url');
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        print('✅ Auth token included in request');
      } else {
        print('⚠️ No auth token - wishlist status will be unavailable');
      }
      final response = await http.get(
        Uri.parse(url),
        headers: headers, // ✅ Add headers to request
      );

      print('DEBUG: API response status code: ${response.statusCode}');

      if (response.statusCode < 300) {
        final jsonData = json.decode(response.body);
        final List productsJson = jsonData['data'];

        // ✅ ADD: Print first product to verify in_wishlist field
        if (productsJson.isNotEmpty) {
          print('🔍 FIRST PRODUCT JSON:');
          print(JsonEncoder.withIndent('  ').convert(productsJson[0]));
        }

        final newProducts =
            productsJson.map((json) => Product.fromJson(json)).toList();

        // Append or replace products
        final allProducts =
            page == 1 ? newProducts : [...state.products, ...newProducts];

        // Check if there are more pages
        bool hasMore = newProducts.length >= limit;

        state = state.copyWith(
          products: allProducts,
          isLoadingProducts: false,
          currentPageProducts: page,
          hasMoreProducts: hasMore,
        );
        onProductsLoaded?.call(allProducts);
        print(
          'DEBUG: Successfully fetched ${newProducts.length} products. Total: ${allProducts.length}',
        );
      } else {
        state = state.copyWith(
          isLoadingProducts: false,
          errorProducts: 'Failed to fetch products: ${response.statusCode}',
        );
        print('DEBUG: API returned non-200 status. Error message set.');
      }
    } catch (e) {
      print("DEBUG: An error occurred during API call: $e");
      state = state.copyWith(
        isLoadingProducts: false,
        errorProducts: 'An error occurred: $e',
      );
    }
  }

  // Load more products for the current category
  Future<void> loadMoreProducts() async {
    // ✅ CRITICAL FIX: Check if already loading
    if (state.isLoadingProducts || !state.hasMoreProducts) {
      print('⏸️ Skipping loadMore - already loading or no more products');
      return; // Exit immediately
    }

    final nextPage = state.currentPageProducts + 1;

    // ✅ Set loading flag IMMEDIATELY
    state = state.copyWith(isLoadingProducts: true);

    print('📄 Loading page $nextPage for category: $lastCategoryId');

    await fetchProductsByCategory(lastCategoryId!, page: nextPage, limit: 20);
  }

  /// Sort products by price
  void sortProducts({
    required String sortOrder,
    bool isDeals = false,
    bool isRecommended = false,
  }) {
    if (isDeals) {
      if (state.todaysDeals.isEmpty) return;
      final sorted = List<Product>.from(state.todaysDeals)..sort(
        (a, b) =>
            sortOrder == 'asc'
                ? a.price.compareTo(b.price)
                : b.price.compareTo(a.price),
      );
      state = state.copyWith(todaysDeals: sorted);
    } else if (isRecommended) {
      if (state.recommended.isEmpty) return;
      final sorted = List<Product>.from(state.recommended)..sort(
        (a, b) =>
            sortOrder == 'asc'
                ? a.price.compareTo(b.price)
                : b.price.compareTo(a.price),
      );
      state = state.copyWith(recommended: sorted);
    } else {
      if (state.products.isEmpty) return;
      final sorted = List<Product>.from(state.products)..sort(
        (a, b) =>
            sortOrder == 'asc'
                ? a.price.compareTo(b.price)
                : b.price.compareTo(a.price),
      );
      state = state.copyWith(products: sorted);
    }
  }

  Future<void> fetchProductsFromApi(
    String apiUrl, {
    required bool isDeal,
    int page = 1,
    int limit = 20,
  }) async {
    if (isDeal) {
      state = state.copyWith(isLoadingDeals: page == 1, errorDeals: null);
    } else {
      state = state.copyWith(
        isLoadingRecommended: page == 1,
        errorRecommended: null,
      );
    }

    try {
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'USER_TOKEN');
      final url = '$apiUrl?page=$page&limit=$limit';

      final headers = <String, String>{'Content-Type': 'application/json'};

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: headers, // ✅ Add headers
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List productsJson = jsonData['data'];
        final newProducts =
            productsJson.map((json) => Product.fromJson(json)).toList();

        if (isDeal) {
          final allDeals =
              page == 1 ? newProducts : [...state.todaysDeals, ...newProducts];
          final hasMore = newProducts.length >= limit;

          state = state.copyWith(
            todaysDeals: allDeals,
            isLoadingDeals: false,
            errorDeals: null,
            currentPageDeals: page,
            hasMoreDeals: hasMore,
          );
          onProductsLoaded?.call(allDeals);
        } else {
          final allRecommended =
              page == 1 ? newProducts : [...state.recommended, ...newProducts];
          final hasMore = newProducts.length >= limit;

          state = state.copyWith(
            recommended: allRecommended,
            isLoadingRecommended: false,
            errorRecommended: null,
            currentPageRecommended: page,
            hasMoreRecommended: hasMore,
          );
          onProductsLoaded?.call(allRecommended);
        }
      } else {
        if (isDeal) {
          state = state.copyWith(
            errorDeals: 'Failed to fetch deals: ${response.statusCode}',
            isLoadingDeals: false,
          );
        } else {
          state = state.copyWith(
            errorRecommended:
                'Failed to fetch recommended: ${response.statusCode}',
            isLoadingRecommended: false,
          );
        }
      }
    } catch (e) {
      if (isDeal) {
        state = state.copyWith(errorDeals: 'Error: $e', isLoadingDeals: false);
      } else {
        state = state.copyWith(
          errorRecommended: 'Error: $e',
          isLoadingRecommended: false,
        );
      }
      print("Error fetching products: $e");
    }
  }

  // Load more deals
  Future<void> loadMoreDeals(String apiUrl) async {
    // ✅ Same fix for deals
    if (state.isLoadingDeals || !state.hasMoreDeals) {
      print('⏸️ Skipping loadMoreDeals - already loading');
      return;
    }

    final nextPage = state.currentPageDeals + 1;
    state = state.copyWith(isLoadingDeals: true);

    await fetchProductsFromApi(apiUrl, isDeal: true, page: nextPage, limit: 20);
  }

  Future<void> loadMoreRecommended(String apiUrl) async {
    // ✅ Same fix for recommended
    if (state.isLoadingRecommended || !state.hasMoreRecommended) {
      print('⏸️ Skipping loadMoreRecommended - already loading');
      return;
    }

    final nextPage = state.currentPageRecommended + 1;
    state = state.copyWith(isLoadingRecommended: true);

    await fetchProductsFromApi(
      apiUrl,
      isDeal: false,
      page: nextPage,
      limit: 20,
    );
  }
}
