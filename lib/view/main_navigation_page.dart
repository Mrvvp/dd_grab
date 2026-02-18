import 'package:dd_grab/view/Category.dart';
import 'package:dd_grab/view/bottom_nav_bar.dart';
import 'package:dd_grab/view/home_page.dart';
import 'package:dd_grab/view/myproifle.dart';
import 'package:dd_grab/view/wishlist.dart';
import 'package:dd_grab/viewmodels/bottom_nav_bar_vm.dart';
import 'package:dd_grab/viewmodels/cart_vm.dart';
import 'package:dd_grab/viewmodels/whislist_vm.dart';
import 'package:dd_grab/viewmodels/address_vm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MainNavigationPage extends ConsumerStatefulWidget {
  const MainNavigationPage({super.key});

  @override
  ConsumerState<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends ConsumerState<MainNavigationPage> {
  DateTime? lastBackPressTime;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    // Initialize data after first frame to avoid blocking UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    if (_isInitialized) return;

    try {
      final secureStorage = const FlutterSecureStorage();
      final token = await secureStorage.read(key: 'USER_TOKEN');

      if (token != null && token.isNotEmpty) {
        print('👤 Logged in user - preloading data');

        // Load user-specific data in parallel (non-blocking)
        Future.wait([
          ref
              .read(cartViewModelProvider.notifier)
              .fetchCart()
              .catchError((_) {}),
          ref
              .read(wishlistProvider.notifier)
              .fetchWishlist()
              .catchError((_) {}),
          ref
              .read(addressViewModelProvider.notifier)
              .fetchAddresses()
              .catchError((_) {}),
        ]);

        print('✅ User data loading started');
      } else {
        print('👤 Guest user browsing - clearing addresses');
        // Clear addresses for guest users
        ref.read(addressViewModelProvider.notifier).clearAddresses();
      }
    } catch (e) {
      print('⚠️ Initialization error: $e');
    } finally {
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(bottomNavProvider);

    final screens = const [
      HomePage(),
      CategoryPage(),
      WishlistPage(),
      ProfilePage(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final now = DateTime.now();

        if (lastBackPressTime == null ||
            now.difference(lastBackPressTime!) > const Duration(seconds: 2)) {
          lastBackPressTime = now;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Press back again to exit"),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );

          return;
        }

        SystemNavigator.pop(); // exit app
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: IndexedStack(index: currentIndex, children: screens),
        bottomNavigationBar: const BottomNavBarWidget(),
      ),
    );
  }
}
