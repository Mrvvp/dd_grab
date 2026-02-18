import 'dart:convert';
import 'package:dd_grab/config/api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/category_model.dart';

final homeViewModelProvider = ChangeNotifierProvider((ref) => HomeViewModel());

class HomeViewModel extends ChangeNotifier {
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  bool _hasError = false;

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  HomeViewModel() {
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.categoryMain),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body)['data'];
        _categories = data.map((e) => CategoryModel.fromJson(e)).toList();
      } else {
        _hasError = true;
      }
    } catch (e) {
      _hasError = true;
      if (kDebugMode) print('Fetch error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
