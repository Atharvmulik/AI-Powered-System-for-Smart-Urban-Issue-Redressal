// lib/config/api_config.dart

class ApiConfig {
  // Base URL for API requests
  // For Android emulator: use 10.0.2.2 to connect to localhost
  static const String baseUrl = 'http://10.0.2.2:8000';
  
  
  // Authentication endpoints
  static const String loginEndpoint = '$baseUrl/auth/login';
  static const String registerEndpoint = '$baseUrl/auth/register';
  static const String logoutEndpoint = '$baseUrl/auth/logout';
  static const String reportIssueEndpoint = '/issues/report';
  static const String getIssuesEndpoint = '/issues';
  static const String uploadImageEndpoint = '/upload';

  static const String refreshToken = '$baseUrl/auth/refresh';
  
  // User management endpoints
  static const String users = '$baseUrl/api/users';
  static const String userProfile = '$baseUrl/api/users/profile';
  
  // Issue management endpoints
  static const String issues = '$baseUrl/api/issues';
  static String issueById(int id) => '$baseUrl/api/issues/$id';
  static const String issuesByStatus = '$baseUrl/api/issues/status';
  static const String issuesByCategory = '$baseUrl/api/issues/category';
  
  // AI Prediction endpoint
  static const String predict = '$baseUrl/api/predict';
  
  // Categories and statuses
  static const String categories = '$baseUrl/api/categories';
  static const String statuses = '$baseUrl/api/statuses';
  
  // Statistics and analytics
  static const String statsOverview = '$baseUrl/api/stats/overview';
  static const String statsTimeline = '$baseUrl/api/stats/timeline';
  
  // Image upload endpoint
  static const String uploadImage = '$baseUrl/api/upload';
  
  // Timeout settings
  static const int connectTimeout = 5000; // 5 seconds
  static const int receiveTimeout = 15000; // 15 seconds
  
  // Get the appropriate base URL based on platform
  static String getBaseUrl() {
    return baseUrl;
  }
  
  // Check if we're using a local development server
  static bool isLocalServer() {
    return baseUrl.contains('localhost') || 
           baseUrl.contains('10.0.2.2') || 
           baseUrl.contains('192.168.');
  }
}