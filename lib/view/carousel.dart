import 'package:dd_grab/viewmodels/carousel_vm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class BannerCarousel extends ConsumerStatefulWidget {
  const BannerCarousel({super.key});

  @override
  ConsumerState<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends ConsumerState<BannerCarousel> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.95);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = ref.watch(bannerProvider);
    final currentPage = ref.watch(currentBannerIndexProvider);

    // ✅ Return empty container if no banners to avoid layout issues
    if (banners.isEmpty) {
      return const SizedBox(
        height: 186,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: _pageController,
            itemCount: banners.length,
            onPageChanged: (index) {
              ref.read(currentBannerIndexProvider.notifier).state = index;
            },
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.pink.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              banner.title,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              banner.subtitle,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Container(
                            //   color: Colors.white,
                            //   padding: const EdgeInsets.all(8.0),
                            //   child: const Text('Shop Now'),
                            // ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 10,
                        bottom: 0,
                        child: Image.asset(
                          banner.imagePath,
                          height: 130,
                          // ✅ Cache images at optimal resolution
                          cacheHeight: 260, // 2x for retina displays
                          fit: BoxFit.contain,
                          // ✅ Error handling for missing images
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 130,
                              width: 100,
                              color: Colors.grey[300],
                              child: const Icon(Icons.error_outline),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Dot Indicator
        const SizedBox(height: 8),
        _buildDotIndicator(banners.length, currentPage),
      ],
    );
  }

  // ✅ Extracted to separate method with const optimization
  Widget _buildDotIndicator(int count, int currentPage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: isActive ? 20 : 8,
          decoration: BoxDecoration(
            color: isActive ? Colors.black : Colors.grey,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
