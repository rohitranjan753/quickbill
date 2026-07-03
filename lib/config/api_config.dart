/// API Configuration for QuickBill Backend
class ApiConfig {
  // Backend API base URL
  // TODO: Update this with your actual backend URL
  static String get baseUrl => _getBaseUrl();

  // Environment detection
  static bool get isDevelopment => _env == Environment.development;
  static bool get isProduction => _env == Environment.production;

  // Private
  static const Environment _env = Environment.development;

  static String _getBaseUrl() {
    switch (_env) {
      case Environment.development:
        // Local development server
        return 'http://localhost:3000/api';
      case Environment.staging:
        // Staging server
        return 'https://quickbill-backend-staging.vercel.app/api';
      case Environment.production:
        // Production server
        return 'https://quickbill-backend.vercel.app/api';
    }
  }

  // API Endpoints
  static String get storesNearby => '$baseUrl/stores/nearby';
  static String storeById(String id) => '$baseUrl/stores/$id';
  static String get stores => '$baseUrl/stores';

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 10);
  static const Duration longTimeout = Duration(seconds: 30);
}

enum Environment {
  development,
  staging,
  production,
}
