import 'dart:convert';
import 'package:dd_grab/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/category_model.dart';

final categoryViewModelProvider = ChangeNotifierProvider(
  (ref) => CategoryViewModel(),
);

class CategoryViewModel extends ChangeNotifier {
  List<CategoryModel> _categories = [];
  int _selectedIndex = 0;

  List<CategoryModel> get categories => _categories;
  int get selectedIndex => _selectedIndex;

  List<String> get currentSubcategories {
    return _categories[_selectedIndex].subcategories
        .map((e) => e['slug'] as String)
        .toList();
  }

  CategoryViewModel() {
    fetchMainCategories();
  }

  Future<void> fetchMainCategories() async {
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.categoryList),
      );

      if (res.statusCode != 200) {
        debugPrint('Main cat error: ${res.statusCode}');
        return;
      }

      final List data = jsonDecode(res.body)['data'];
      _categories = data.map((e) => CategoryModel.fromJson(e)).toList();
      notifyListeners();

      if (_categories.isNotEmpty) {
        _selectedIndex = 0; // Optionally preload the first
      }
    } catch (e) {
      debugPrint('Main cat exception: $e');
    }
  }

  void selectCategory(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
}
