import 'package:dd_grab/models/product_model.dart';
import 'package:dd_grab/service/search_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(
    baseUrl: 'https://dd-api.codesprint.cloud/api/v1',
  ); // replace with actual URL
});

final productSearchProvider =
    StateNotifierProvider<ProductSearchNotifier, AsyncValue<List<Product>>>((
      ref,
    ) {
      final repo = ref.watch(productRepositoryProvider);
      return ProductSearchNotifier(repo);
    });

class ProductSearchNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final ProductRepository repo;

  int currentPage = 1;
  bool hasMore = true;
  String currentQuery = '';

  ProductSearchNotifier(this.repo) : super(const AsyncValue.data([]));

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = const AsyncValue.data([]);
      currentPage = 1;
      hasMore = true;
      currentQuery = '';
      return;
    }

    currentQuery = query;
    currentPage = 1;
    hasMore = true;
    state = const AsyncValue.loading();
    try {
      final products = await repo.searchProducts(
        currentQuery,
        page: currentPage,
      );
      state = AsyncValue.data(products);
      hasMore = products.length >= 15; // if less than limit, no more pages
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      hasMore = false;
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || currentQuery.isEmpty) return;

    currentPage++;
    try {
      final newProducts = await repo.searchProducts(
        currentQuery,
        page: currentPage,
      );
      if (newProducts.isEmpty) {
        hasMore = false;
      } else {
        final currentProducts = state.value ?? [];
        final allProducts = [...currentProducts, ...newProducts];
        state = AsyncValue.data(allProducts);
        hasMore = newProducts.length >= 15;
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
