import 'package:dd_grab/models/address_model.dart';
import 'package:dd_grab/view/address.dart';
import 'package:dd_grab/view/cart.dart';
import 'package:dd_grab/view/icon_badge.dart';
import 'package:dd_grab/view/notification.dart';
import 'package:dd_grab/view/search_page.dart';
import 'package:dd_grab/view/welcome.dart';
import 'package:dd_grab/viewmodels/address_vm.dart';
import 'package:dd_grab/viewmodels/cart_vm.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomHomeAppBar extends ConsumerWidget {
  const CustomHomeAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressState = ref.watch(addressViewModelProvider);
    final cartState = ref.watch(cartViewModelProvider);

    // Get location text
    final locationText = _getLocationText(addressState.addresses);

    // Get counts
    final cartItemCount = cartState.cartItems.length;
    const notificationCount = 1;

    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          // Yellow background container
          Container(
            decoration: BoxDecoration(
              color: Colors.yellow[600],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
          ),

          // Top-right decorative image
          Positioned(
            top: 0,
            right: 0,
            child: Image.asset(
              'assets/images/appbarlines.png',
              fit: BoxFit.cover,
              cacheWidth: 200, // ✅ Cache at optimal resolution
            ),
          ),

          // Bottom-left decorative image
          Positioned(
            bottom: 0,
            left: 0,
            child: Image.asset(
              'assets/images/appbarlines.png',
              fit: BoxFit.cover,
              cacheWidth: 200, // ✅ Cache at optimal resolution
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location label
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text(
                    'Location',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),

                // Location + Icons Row
                Row(
                  children: [
                    // Location Area
                    Expanded(
                      child: _buildLocationButton(context, locationText),
                    ),

                    const SizedBox(width: 12),

                    // Cart & Notification Icons
                    _buildCartIcon(context, cartItemCount),
                    const SizedBox(width: 16),
                    _buildNotificationIcon(context, notificationCount),
                  ],
                ),

                const SizedBox(height: 16),

                // Search Bar
                _buildSearchBar(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Extract location text logic
  String _getLocationText(List<Address> addresses) {
    if (addresses.isEmpty) return 'Select Address';

    try {
      final defaultAddress = addresses.firstWhere((addr) => addr.isDefault);
      return '${defaultAddress.city} - ${defaultAddress.zip}';
    } catch (_) {
      return 'Select Address';
    }
  }

  // ✅ Extract location button
  Widget _buildLocationButton(BuildContext context, String locationText) {
    return InkWell(
      onTap: () => _handleLocationTap(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.location_on, color: Colors.red),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              locationText,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.black),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Extract cart icon
  Widget _buildCartIcon(BuildContext context, int count) {
    return GestureDetector(
      onTap: () => _handleCartTap(context),
      child: IconWithBadge(
        imagePath: 'assets/images/shopping-cart 1.png',
        count: count,
      ),
    );
  }

  // ✅ Extract notification icon
  Widget _buildNotificationIcon(BuildContext context, int count) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationPage()),
        );
      },
      child: IconWithBadge(
        imagePath: 'assets/images/alarm-bell 1.png',
        count: count,
      ),
    );
  }

  // ✅ Extract search bar
  Widget _buildSearchBar(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchPage()),
        );
      },
      child: IgnorePointer(
        child: TextField(
          decoration: InputDecoration(
            hintText: "Search",
            hintStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w300,
            ),
            prefixIcon: const Icon(CupertinoIcons.search),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Extract location tap handler
  Future<void> _handleLocationTap(BuildContext context) async {
    final secureStorage = const FlutterSecureStorage();
    final token = await secureStorage.read(key: 'USER_TOKEN');

    if (context.mounted) {
      if (token == null || token.isEmpty) {
        _showLoginPrompt(context, 'Please login to manage addresses');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => WelcomePage()),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddressPage()),
        );
      }
    }
  }

  // ✅ Extract cart tap handler
  Future<void> _handleCartTap(BuildContext context) async {
    final secureStorage = const FlutterSecureStorage();
    final token = await secureStorage.read(key: 'USER_TOKEN');

    if (context.mounted) {
      if (token == null || token.isEmpty) {
        _showLoginPrompt(context, 'Please login to view your cart');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => WelcomePage()),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CartPage()),
        );
      }
    }
  }

  // ✅ Reusable snackbar method
  void _showLoginPrompt(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
