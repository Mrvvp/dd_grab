class CategoryModel {
  final int id;
  final int? parentId; // null for main category
  final String slug;
  final String name;
  late final String iconPath;

  /// Holds full data of each subcategory
  final List<Map<String, dynamic>> subcategories;

  CategoryModel({
    required this.id,
    required this.parentId,
    required this.slug,
    required this.name,
    required this.iconPath,
    required this.subcategories,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final slug = json['slug'] as String? ?? '';
    final List<Map<String, dynamic>> subs =
        (json['subcategories'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

    return CategoryModel(
      id: json['id'] as int,
      parentId: json['parent_id'] as int?,
      slug: slug,
      name: slug.replaceAll('-', ' ').toUpperCase(),
      iconPath: getIconPath(slug),
      subcategories: subs,
    );
  }

  static String getIconPath(String slug) {
    // Use ddgrab icon as default for all categories
    // This ensures images work even when category names/slugs change
    return 'assets/images/ddgrab appicon.png';
  }
}
