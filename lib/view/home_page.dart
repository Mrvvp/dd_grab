import 'package:dd_grab/config/api_config.dart';
import 'package:dd_grab/view/carousel.dart';
import 'package:dd_grab/view/category_item.dart';
import 'package:dd_grab/view/product_list.dart';
import 'package:dd_grab/view/reusable_appbar.dart';
import 'package:dd_grab/viewmodels/address_vm.dart';
import 'package:dd_grab/viewmodels/location_vm.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/home_view_model.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();

    // ✅ Delay all data fetching until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch addresses (already optimized)
      ref.read(addressViewModelProvider.notifier).fetchAddresses();
      
      // Try to get current location if no saved addresses
      final addressState = ref.read(addressViewModelProvider);
      if (addressState.addresses.isEmpty) {
        ref.read(locationViewModelProvider.notifier).getCurrentLocation();
      }

      // Fetch categories if not already loaded
      final homeViewModel = ref.read(homeViewModelProvider);
      if (homeViewModel.categories.isEmpty && !homeViewModel.isLoading) {
        // Assuming you have a method to fetch categories
        // ref.read(homeViewModelProvider.notifier).fetchCategories();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomHomeAppBar(),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categories Section
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8, left: 8),
                    child: SizedBox(
                      height: 120,
                      child: _buildCategoriesSection(),
                    ),
                  ),

                  // Banner Carousel
                  BannerCarousel(),

                  // Deals Section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      "Deals You Will Love",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 110, child: _buildDealsSection()),

                  // Recommendations Section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      "Recommendations for you",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 110, child: _buildRecommendationsSection()),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Extracted to separate method for better performance
  Widget _buildCategoriesSection() {
    final viewModel = ref.watch(homeViewModelProvider);

    if (viewModel.isLoading) {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        itemBuilder:
            (context, index) =>
                const SizedBox(width: 80, child: CategoryItemShimmer()),
      );
    } else if (viewModel.hasError) {
      return const Center(child: Text('Error loading categories'));
    } else {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: viewModel.categories.length,
        itemBuilder: (context, index) {
          final cat = viewModel.categories[index];
          final slug = cat.slug;
          return SizedBox(
            width: 80,
            child: CategoryItem(
              imagePath: cat.iconPath,
              label: slug.replaceAll('-', ' ').toUpperCase(),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => ProductListPage(
                          categoryName: slug,
                          categoryId: '',
                          apiUrl: ApiConfig.productTodaysDeal,
                          isDeals: true,
                          isRecommended: false,
                        ),
                  ),
                );
              },
            ),
          );
        },
      );
    }
  }

  // ✅ Extracted deals section with const optimization
  Widget _buildDealsSection() {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 16),
      children: const [
        _DealCard(
          title: "Today's Deal",
          imageUrl: "assets/images/Rectangle 84.png",
          categoryName: "Today's Deals",
          isDeals: true,
        ),
        _DealCard(
          title: "Up to 50% off",
          imageUrl: "assets/images/image.png",
          categoryName: "Up to 50% Off",
          isDeals: true,
        ),
        _DealCard(
          title: "Under ₹799",
          imageUrl: "assets/images/Rectangle 84 (1).png",
          categoryName: "Under ₹799",
          isDeals: true,
        ),
        _DealCard(
          title: "From ₹399",
          imageUrl: "assets/images/Rectangle1.png",
          categoryName: "From ₹399",
          isDeals: true,
        ),
      ],
    );
  }

  // ✅ Extracted recommendations section with const optimization
  Widget _buildRecommendationsSection() {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 16),
      children: const [
        _DealCard(
          title: "Hair Care",
          imageUrl: "assets/images/haircare.png",
          categoryName: "Hair Care",
          isDeals: false,
          isRecommended: true,
        ),
        _DealCard(
          title: "iPhone 15 Plus",
          imageUrl: "assets/images/phone2.png",
          categoryName: "iPhone 15 Plus",
          isDeals: false,
          isRecommended: true,
        ),
        _DealCard(
          title: "Air Purifier",
          imageUrl: "assets/images/airpurifier.png",
          categoryName: "Air Purifier",
          isDeals: false,
          isRecommended: true,
        ),
        _DealCard(
          title: "Dining Sets",
          imageUrl: "assets/images/table.png",
          categoryName: "Dining Sets",
          isDeals: false,
          isRecommended: true,
        ),
      ],
    );
  }
}

// ✅ Created stateless const widget for better performance
class _DealCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String categoryName;
  final bool isDeals;
  final bool isRecommended;

  const _DealCard({
    required this.title,
    required this.imageUrl,
    required this.categoryName,
    this.isDeals = false,
    this.isRecommended = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => ProductListPage(
                  apiUrl: isDeals
                      ? ApiConfig.productTodaysDeal
                      : ApiConfig.productRecommended,
                  categoryName: categoryName,
                  categoryId: '',
                  isDeals: isDeals,
                  isRecommended: isRecommended,
                ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 100,
        child: Column(
          children: [
            // ✅ Precache images for better performance
            Image.asset(
              imageUrl,
              width: 100,
              height: 70,
              fit: BoxFit.cover,
              cacheWidth: 200, // ✅ Cache at 2x resolution
              cacheHeight: 140,
              errorBuilder:
                  (_, __, ___) => Container(
                    color: Colors.grey[200],
                    width: 100,
                    height: 70,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// Keep your original DealsCard for backward compatibility if needed
class DealsCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final VoidCallback? onTap;

  const DealsCard({
    super.key,
    required this.title,
    required this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 100,
        child: Column(
          children: [
            Image.asset(
              imageUrl,
              width: 100,
              height: 70,
              fit: BoxFit.cover,
              cacheWidth: 200,
              cacheHeight: 140,
              errorBuilder:
                  (_, __, ___) => Container(
                    color: Colors.grey[200],
                    width: 100,
                    height: 70,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
