import 'package:dd_grab/view/add_address.dart';
import 'package:dd_grab/viewmodels/address_vm.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddressPage extends ConsumerStatefulWidget {
  const AddressPage({super.key});

  @override
  ConsumerState<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends ConsumerState<AddressPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(addressViewModelProvider.notifier).fetchAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addressViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow.shade600,
        surfaceTintColor: Colors.yellow.shade600,
        title: const Text('My Addresses'),
        actions: [
          IconButton(
            onPressed: () async {
              final shouldRefresh = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddressFormPage()),
              );
              if (shouldRefresh == true) {
                await ref
                    .read(addressViewModelProvider.notifier)
                    .fetchAddresses(forceRefresh: true);
              }
            },
            icon: const Icon(CupertinoIcons.add),
          ),
        ],
      ),
      body:
          state.isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.black),
              )
              : state.error.isNotEmpty
              ? Center(child: Text(state.error))
              : state.addresses.isEmpty
              ? const Center(child: Text('No addresses found.'))
              : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.addresses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final address = state.addresses[index];

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(blurRadius: 2, color: Colors.black12),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔘 Radio Button
                        IconButton(
                          icon: Icon(
                            address.isDefault
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: Colors.orange,
                          ),
                          onPressed: () async {
                            if (address.isDefault) return;

                            final error = await ref
                                .read(addressViewModelProvider.notifier)
                                .setDefaultAddress(address.id);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    error ?? "Default address set successfully",
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.orange,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }

                            await ref
                                .read(addressViewModelProvider.notifier)
                                .fetchAddresses(forceRefresh: true);
                          },
                        ),

                        // 📝 Address Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (address.isDefault)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    "Default",
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                '${address.firstName} ${address.lastName}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${address.address1}, ${address.address2},\n'
                                '${address.city}, ${address.state} ${address.zip}, ${address.country}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),

                        // ✏️ Edit Button
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) =>
                                            AddressFormPage(address: address),
                                  ),
                                );

                                if (result == true) {
                                  await ref
                                      .read(addressViewModelProvider.notifier)
                                      .fetchAddresses(forceRefresh: true);
                                }
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(Icons.edit_outlined, size: 20),
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                final error = await ref
                                    .read(addressViewModelProvider.notifier)
                                    .deleteAddress(address.id);

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        error ?? "Address deleted successfully",
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Colors.black,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(CupertinoIcons.delete, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
