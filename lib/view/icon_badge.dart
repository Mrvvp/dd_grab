import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;

/// Reusable widget for an icon with a badge
class IconWithBadge extends StatelessWidget {
  final String imagePath;
  final int count;
  final VoidCallback? onTap;

  const IconWithBadge({
    super.key,
    required this.imagePath,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: badges.Badge(
        showBadge: count > 0,
        badgeContent: Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        badgeStyle: const badges.BadgeStyle(
          badgeColor: Colors.red,
          padding: EdgeInsets.all(8),
          borderRadius: BorderRadius.all(Radius.circular(15)),
          elevation: 2,
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
        badgeAnimation: const badges.BadgeAnimation.scale(
          animationDuration: Duration(milliseconds: 200),
        ),
        position: badges.BadgePosition.topEnd(top: -5, end: 0),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Image.asset(imagePath, width: 24, height: 24),
        ),
      ),
    );
  }
}
