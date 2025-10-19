import 'package:dd_grab/models/carousel_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bannerProvider = Provider<List<BannerModel>>((ref) {
  return [
    BannerModel(
      title: 'Up 50% off',
      subtitle: 'Iphone 16 + 128 GB',
      imagePath: 'assets/images/image 2.png',
    ),
    BannerModel(
      title: 'Special Deal',
      subtitle: 'Redmi A4',
      imagePath: 'assets/images/image 2.png',
    ),
  ];
});

final currentBannerIndexProvider = StateProvider<int>((ref) => 0);
