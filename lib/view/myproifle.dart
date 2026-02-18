import 'package:dd_grab/view/OrderList.dart';
import 'package:dd_grab/view/address.dart';
import 'package:dd_grab/view/editprofile.dart';
import 'package:dd_grab/view/help.dart';
import 'package:dd_grab/view/return&refund.dart';
import 'package:dd_grab/view/reusable_appbar.dart';
import 'package:dd_grab/view/welcome.dart';
import 'package:dd_grab/viewmodels/profile_vm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> with WidgetsBindingObserver {
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAuthentication();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshProfileIfAuthenticated();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh profile when page becomes visible again
    _refreshProfileIfAuthenticated();
  }

  Future<void> _checkAuthentication() async {
    final secureStorage = const FlutterSecureStorage();
    final token = await secureStorage.read(key: 'USER_TOKEN');

    if (mounted) {
      setState(() {
        _isAuthenticated = token != null && token.isNotEmpty;
      });
    }

    // Only fetch profile if authenticated
    if (_isAuthenticated) {
      Future.microtask(() {
        ref.read(profileViewModelProvider.notifier).fetchProfileData();
      });
    }
  }

  Future<void> _refreshProfileIfAuthenticated() async {
    final secureStorage = const FlutterSecureStorage();
    final token = await secureStorage.read(key: 'USER_TOKEN');
    
    if (mounted) {
      setState(() {
        _isAuthenticated = token != null && token.isNotEmpty;
      });
    }

    if (token == null || token.isEmpty) {
      // If no token, clear profile data
      ref.read(profileViewModelProvider.notifier).clearProfileData();
    } else {
      // If token exists, refresh profile data
      ref.read(profileViewModelProvider.notifier).refreshProfileData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileVM = ref.watch(profileViewModelProvider);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomHomeAppBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "My Profile",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Profile Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(blurRadius: 2, color: Colors.black12),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.black,
                            child: Text(
                              profileVM.name.isNotEmpty
                                  ? profileVM.name
                                      .trim()
                                      .split(' ')
                                      .map((e) => e.isNotEmpty ? e[0] : '')
                                      .take(2)
                                      .join()
                                      .toUpperCase()
                                  : '',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${profileVM.name} ${profileVM.lastname}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  profileVM.email,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  profileVM.phone,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              final secureStorage =
                                  const FlutterSecureStorage();
                              final token = await secureStorage.read(
                                key: 'USER_TOKEN',
                              );

                              if (token == null || token.isEmpty) {
                                // Guest user - show message and redirect to login
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please login to continue'),
                                      backgroundColor: Colors.black,
                                      behavior: SnackBarBehavior.floating,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );

                                  // Navigate to welcome/login page
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => WelcomePage(),
                                    ),
                                  );
                                }
                                return;
                              }
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => EditProfilePage(
                                        name: profileVM.name,
                                        lastName: profileVM.lastname,
                                        username: profileVM.username,
                                        email: profileVM.email,
                                        phone: profileVM.phone,
                                      ),
                                ),
                              );
                              // Refresh profile after returning from edit page
                              if (mounted) {
                                _refreshProfileIfAuthenticated();
                              }
                            },
                            child: const Text(
                              "Edit",
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Row(
                    //   children: [
                    //     Image.asset('assets/images/rewards.png', height: 80),
                    //     Expanded(
                    //       child: Container(
                    //         padding: const EdgeInsets.all(12),
                    //         decoration: BoxDecoration(
                    //           color: Colors.blue[800],
                    //           borderRadius: BorderRadius.circular(12),
                    //         ),
                    //         child: Row(
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           children: [
                    //             const SizedBox(width: 10),
                    //             Expanded(
                    //               child: Column(
                    //                 crossAxisAlignment:
                    //                     CrossAxisAlignment.start,
                    //                 children: const [
                    //                   _RewardRow(
                    //                     label: "RewardStatus",
                    //                     value: "Unpaid",
                    //                   ),
                    //                   _RewardRow(
                    //                     label: "Wallet Balance",
                    //                     value: "23,000 INR",
                    //                   ),
                    //                   _RewardRow(
                    //                     label: "Unused Balance",
                    //                     value: "22,000 INR",
                    //                   ),
                    //                   _RewardRow(
                    //                     label: "Total",
                    //                     value: "66,000 INR",
                    //                   ),
                    //                   _RewardRow(
                    //                     label: "Used Amount",
                    //                     value: "12,000 INR",
                    //                   ),
                    //                 ],
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    // const SizedBox(height: 16),
                    _profileOption(
                      title: "Orders",
                      onTap: () async {
                        final secureStorage = const FlutterSecureStorage();
                        final token = await secureStorage.read(
                          key: 'USER_TOKEN',
                        );

                        if (token == null || token.isEmpty) {
                          // Guest user - show message and redirect to login
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please login to continue'),
                                backgroundColor: Colors.black,
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2),
                              ),
                            );

                            // Navigate to welcome/login page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WelcomePage(),
                              ),
                            );
                          }
                          return;
                        }
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderListPage(),
                            ),
                          );
                        }
                      },
                    ),
                    Divider(color: Colors.grey.shade300),
                    _profileOption(
                      title: "Address",
                      onTap: () async {
                        // Check authentication before opening address page
                        final secureStorage = const FlutterSecureStorage();
                        final token = await secureStorage.read(
                          key: 'USER_TOKEN',
                        );

                        if (token == null || token.isEmpty) {
                          // Guest user - show message and redirect to login
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please login to continue'),
                                backgroundColor: Colors.black,
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2),
                              ),
                            );

                            // Navigate to welcome/login page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WelcomePage(),
                              ),
                            );
                          }
                          return;
                        }

                        // User is authenticated - open address page
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddressPage(),
                            ),
                          );
                        }
                      },
                    ),

                    Divider(color: Colors.grey.shade300),
                    _profileOption(
                      title: "Help",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Help()),
                        );
                      },
                    ),
                    Divider(color: Colors.grey.shade300),
                    _profileOption(
                      title: "Returns & Refunds",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReturnAndRefund(),
                          ),
                        );
                      },
                    ),
                    Divider(color: Colors.grey.shade300),
                    const SizedBox(height: 20),
                    if (_isAuthenticated)
                      GestureDetector(
                        onTap: () {
                          profileVM.logout(context, ref); // pass ref here
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.black),
                            ),
                            child: Center(
                              child:
                                  profileVM.isLoggingOut
                                      ? const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: SizedBox(
                                          width: 20, // smaller width
                                          height: 20, // smaller height
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2, // thinner line
                                            color: Colors.black,
                                          ),
                                        ),
                                      )
                                      : const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          'Logout',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileOption({required String title, required VoidCallback onTap}) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward, size: 16),
      onTap: onTap,
    );
  }
}

// class _RewardRow extends StatelessWidget {
//   final String label;
//   final String value;
//   const _RewardRow({required this.label, required this.value});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 2),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(color: Colors.white, fontSize: 12),
//           ),
//           Text(
//             value,
//             style: const TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
