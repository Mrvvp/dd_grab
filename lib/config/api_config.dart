/// API Configuration
/// Centralized location for all API endpoints and base URLs
class ApiConfig {
  // Environment Configuration
  // Set to true for live/production, false for staging
  static const bool isProduction = true;

  // Base URLs
  static const String stagingBaseUrl = 'https://dd-api.codesprint.cloud/api/v1';
  static const String productionBaseUrl = 'https://api.ddgrab.com/api/v1';

  // Image Storage Base URLs
  static const String stagingImageBaseUrl =
      'https://ecom-stag.codesprint.cloud/storage';
  static const String productionImageBaseUrl = 'https://ddgrab.com/storage';

  // Base URL for the API (automatically selects based on environment)
  static const String baseUrl =
      isProduction ? productionBaseUrl : stagingBaseUrl;

  // Image Storage URL (automatically selects based on environment)l̥
  static const String imageBaseUrl =
      isProduction ? productionImageBaseUrl : stagingImageBaseUrl;

  // Helper method to build full image URL
  static String getImageUrl(String imagePath) {
    if (imagePath.isEmpty) return '';
    // Remove leading slash if present to avoid double slashes
    final cleanPath =
        imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
    return '$imageBaseUrl/$cleanPath';
  }

  // API Endpoints
  static const String cart = '$baseUrl/cart';
  static const String addToCart = '$baseUrl/cart/add-to-cart';
  static const String removeFromCart = '$baseUrl/cart/remove-from-cart';

  static const String orderInitiate = '$baseUrl/order/initiate-order';
  static const String orderList = '$baseUrl/order/list-order';

  static const String productById = '$baseUrl/product/product-by-id';
  static const String checkPincode = '$baseUrl/product/check-pincode';
  static const String wishlist = '$baseUrl/product/wishlist';
  static const String toggleWishlist = '$baseUrl/product/toggle-wishlist';

  static const String categoryMain = '$baseUrl/category/main';

  static const String searchProduct = '$baseUrl/search/product';

  static const String userAddresses = '$baseUrl/user/get-addresses';
  static const String userAddAddress = '$baseUrl/user/add-address';
  static const String userEditAddress = '$baseUrl/user/edit-address';
  static const String userSetDefaultAddress =
      '$baseUrl/user/set-default-address';
  static const String userDeleteAddress = '$baseUrl/user/delete-address';

  static const String orderConfirm = '$baseUrl/order/confirm-order';

  static const String productCategory = '$baseUrl/product/category';
  static const String productTodaysDeal = '$baseUrl/product/todays-deal';
  static const String productRecommended = '$baseUrl/product/recommended';

  static const String authSignup = '$baseUrl/auth/user-signup';
  static const String authLogin = '$baseUrl/auth/user-login';
  static const String authChangePassword = '$baseUrl/auth/change-password';

  static const String userProfile = '$baseUrl/user/profile';
  static const String userEditProfile = '$baseUrl/user/edit-profile';

  static const String categoryList = '$baseUrl/category/list';
}
