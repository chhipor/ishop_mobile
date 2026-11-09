class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static const Duration requestTimeout = Duration(seconds: 20);

  static const int lowStockThreshold = 5;

  static const int productsPerPage = 6;

  static const int maxCartQuantity = 99;

  static const int maxProductImages = 10;
}
