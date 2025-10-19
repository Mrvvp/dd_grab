import 'package:cached_network_image/cached_network_image.dart';
import 'package:dd_grab/view/product_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dd_grab/viewmodels/search_vm.dart';
import 'package:shimmer/shimmer.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    Future.microtask(() {
      ref.read(productSearchProvider.notifier).search('a');
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Close to bottom, load more
      ref.read(productSearchProvider.notifier).loadMore();
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
    final searchState = ref.watch(productSearchProvider);
    return Scaffold(
      body: Column(
        children: [
          // Yellow background row with back arrow and search field
          Container(
            color: Colors.yellow[600],
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 12.0,
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  // Use Expanded to make the TextField take the rest of the space
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: TextField(
                        autofocus: true,
                        onChanged:
                            (value) => ref
                                .read(productSearchProvider.notifier)
                                .search(value),
                        decoration: InputDecoration(
                          hintText: "Search for products",
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                          ),
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expanded product list
          Expanded(
            child: searchState.when(
              data: (products) {
                if (products.isEmpty) {
                  return const Center(child: Text('No products found'));
                }
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 10.0,
                      ), // horizontal + vertical spacing
                      child: ListTile(
                        contentPadding:
                            EdgeInsets
                                .zero, // remove default horizontal padding if needed
                        leading: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color.fromARGB(255, 221, 218, 218),
                            ),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: CachedNetworkImage(
                            imageUrl: product.image,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(color: Colors.white),
                                ),
                            errorWidget:
                                (context, url, error) =>
                                    const Icon(Icons.error),
                          ),
                        ),

                        title: Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(height: 1.2),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      ProductDetailsPage(productId: product.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white, // Optional: light neutral background
    );
  }
}
