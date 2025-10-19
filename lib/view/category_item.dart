import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class CategoryItem extends StatelessWidget {
  final String imagePath;
  final String label;
  final VoidCallback? onTap;

  const CategoryItem({
    super.key,
    required this.imagePath,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // 👈  fires when tapped
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.grey.shade200,
              child: Image.asset(
                imagePath,
                width: 30,
                height: 30,
                fit: BoxFit.contain,
              ),
            ),
            Text(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              label,
              style: GoogleFonts.poppins(fontSize: 8),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryItemShimmer extends StatelessWidget {
  const CategoryItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CircleAvatar(radius: 26, backgroundColor: Colors.white),
            const SizedBox(height: 10),
            Container(height: 10, width: 40, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
