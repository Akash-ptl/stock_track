class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://stocktrack-mach.onrender.com',
  );
  static const String login = '$baseUrl/api/auth/login';
  static const String register = '$baseUrl/api/auth/register';
  static const String businesses = '$baseUrl/api/businesses';
  
  static String locations(String businessId) {
    return '$baseUrl/api/businesses/$businessId/locations';
  }

  static String stockItems(String businessId, String locationId) {
    return '$baseUrl/api/businesses/$businessId/locations/$locationId/stock-items';
  }

  static String stockCounts(String businessId) {
    return '$baseUrl/api/businesses/$businessId/stock-counts';
  }

  static String finalizeCount(String businessId, String sessionId) {
    return '$baseUrl/api/businesses/$businessId/stock-counts/$sessionId?status=completed';
  }
}
