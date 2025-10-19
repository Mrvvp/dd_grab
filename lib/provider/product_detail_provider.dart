import 'package:dd_grab/models/product_model.dart';
import 'package:dd_grab/viewmodels/product_details_vm.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final productDetailsProvider =
    ChangeNotifierProvider.family<ProductDetailsViewModel, Product>(
      (ref, product) => ProductDetailsViewModel(),
    );
