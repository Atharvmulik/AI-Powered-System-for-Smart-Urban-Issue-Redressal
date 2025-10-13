class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:8000';
  
  // ✅ CORRECTED: Use the exact endpoints from your backend
  static const String loginEndpoint = '/login';
  static const String registerEndpoint = '/signup'; 
  static const String logoutEndpoint = '/logout';
  static const String reportIssueEndpoint = '/reports/';
  static const String getIssuesEndpoint = '/reports/';
  static const String uploadImageEndpoint = '/upload';
  static const String getUserIssuesEndpoint = '/users/me/reports';

  // Remove or update these if not used
  static const String refreshToken = '/refresh';
  
  // User management endpoints
  static const String users = '/api/users';
  static const String userProfile = '/api/users/profile';
  
  // Issue management endpoints
  static const String issues = '/api/issues';
  static String issueById(int id) => '/api/issues/$id';
  static const String issuesByStatus = '/api/issues/status';
  static const String issuesByCategory = '/api/issues/category';
  
  // AI Prediction endpoint
  static const String predict = '/api/predict';
  
  // Categories and statuses
  static const String categories = '/api/categories';
  static const String statuses = '/api/statuses';
  
  // Statistics and analytics
  static const String statsOverview = '/api/stats/overview';
  static const String statsTimeline = '/api/stats/timeline';
  
  // Image upload endpoint
  static const String uploadImage = '/api/upload';
  
  // Timeout settings
  static const int connectTimeout = 5000;
  static const int receiveTimeout = 15000;
  
  static String getBaseUrl() {
    return baseUrl;
  }
  
  static bool isLocalServer() {
    return baseUrl.contains('localhost') || 
           baseUrl.contains('10.0.2.2') || 
           baseUrl.contains('192.168.');
  }
}