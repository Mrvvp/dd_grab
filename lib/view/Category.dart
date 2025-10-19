import 'package:dd_grab/view/product_list.dart';
import 'package:dd_grab/view/reusable_appbar.dart';
import 'package:dd_grab/viewmodels/category_vm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const CustomHomeAppBar(),
          const Expanded(child: CategoryBody()),
        ],
      ),
    );
  }
}

/* ───────────────────────── Category Body ─────────────────────────────── */
class CategoryBody extends ConsumerWidget {
  const CategoryBody({super.key});

  String sentenceCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(categoryViewModelProvider);

    // Loading state
    if (vm.categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Container(
            width: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: vm.categories.length,
                itemBuilder: (context, i) {
                  final cat = vm.categories[i];
                  final selected = vm.selectedIndex == i;

                  return GestureDetector(
                    onTap:
                        () => ref
                            .read(categoryViewModelProvider)
                            .selectCategory(i),
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            selected
                                ? Colors.white
                                : Colors
                                    .grey
                                    .shade100, // Light yellow for selected
                        border: Border(
                          left: BorderSide(
                            color:
                                selected ? Colors.yellow : Colors.transparent,
                            width: 4,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 5,
                      ),
                      child: Column(
                        children: [
                          Image.asset(cat.iconPath, width: 40, height: 40),
                          const SizedBox(height: 8),
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color:
                                  selected
                                      ? Colors.black
                                      : Colors.grey.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child:
                vm.currentSubcategories.isEmpty
                    ? const Center(child: Text('No sub‑categories'))
                    : ListView.separated(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      itemCount: vm.currentSubcategories.length,
                      separatorBuilder:
                          (_, __) => const Column(
                            children: [
                              SizedBox(height: 16),
                              Divider(thickness: 1),
                              SizedBox(height: 16),
                            ],
                          ),
                      itemBuilder: (_, idx) {
                        final slug = vm.currentSubcategories[idx];
                        final parts = slug.split('-');
                        final section =
                            parts.isNotEmpty ? sentenceCase(parts[0]) : '';
                        final pretty = slug.replaceAll('-', ' ');
                        // Determine if header needed
                        if (idx == 0) {
                        } else {
                          final prevSlug = vm.currentSubcategories[idx - 1];
                          final prevSection =
                              prevSlug.split('-').isNotEmpty
                                  ? sentenceCase(prevSlug.split('-')[0])
                                  : '';
                          if (section != prevSection) {}
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                final selectedMainCat =
                                    vm.categories[vm.selectedIndex];
                                final selectedSubCat =
                                    selectedMainCat
                                        .subcategories[idx]; // 👈 get subcat
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => ProductListPage(
                                          categoryName:
                                              selectedSubCat['slug'].toString(),
                                          categoryId:
                                              selectedSubCat['id']
                                                  .toString(), // ✅ Pass subcategory ID
                                          apiUrl: '',
                                        ),
                                  ),
                                );
                              },
                              child: Text(
                                sentenceCase(pretty),
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
          ),
        ),
      ],
    );
  }
}
