class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:8000';
  
  // ✅ CORRECTED: Exact endpoints from your FastAPI backend
  static const String loginEndpoint = '/login';
  static const String registerEndpoint = '/signup'; 
  static const String reportIssueEndpoint = '/reports/';
  static const String getIssuesEndpoint = '/reports/';
  static const String getUserIssuesEndpoint = '/users/me/reports';
  
  // ✅ CORRECTED: Dashboard endpoints (PUBLIC - no auth required)
  static String get dashboardSummary => "/dashboard/summary";
  static String get dashboardStats => "/dashboard/stats";
  static String get nearbyIssues => "/reports/nearby";
  static String get todayResolved => "/reports/resolved/today";
  static String get todayActivity => "/activity/today";
  static String get categorySummary => "/reports/category-summary";
  
  // ✅ CORRECTED: User complaint tracking (PUBLIC - uses user_email parameter)
  static String get userReportsFiltered => "/users/reports/filtered";
  static String get userReportsSearch => "/users/reports/search";
  static String get reportTimeline => "/reports"; // /{id}/timeline
  
  // ✅ CORRECTED: Reference data endpoints (PUBLIC)
  static String get categories => "/categories";
  static String get urgencyLevels => "/urgency-levels";
  static String get statuses => "/statuses";
  
  // ✅ CORRECTED: Action endpoints (may require auth)
  static String get createReport => "/reports/";
  static String get confirmIssue => "/reports"; 
  static const String userProfile = '/users/me';
  
  // ==================== NEW ADMIN ENDPOINTS ====================
  
  // Admin Issue Management
  static String get adminIssues => "/api/admin/issues";
  static String get adminDepartments => "/api/admin/departments";
  
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
  
  // ✅ Helper method to build full URLs
  static String buildUrl(String endpoint) {
    return baseUrl + endpoint;
  }
  
  // ✅ Helper methods for parameterized endpoints
  static String buildReportTimelineUrl(int reportId) {
    return '$baseUrl/reports/$reportId/timeline';
  }
  
  static String buildConfirmIssueUrl(int reportId) {
    return '$baseUrl/reports/$reportId/confirm';
  }
  
  static String buildUserReportsFilteredUrl(String userEmail, {String statusFilter = 'all'}) {
    return '$baseUrl/users/reports/filtered?user_email=$userEmail&status_filter=$statusFilter';
  }
  
  static String buildUserReportsSearchUrl(String userEmail, String query) {
    return '$baseUrl/users/reports/search?user_email=$userEmail&query=$query';
  }
  
  static String buildNearbyIssuesUrl(double lat, double lng, {double radius = 5.0}) {
    return '$baseUrl/reports/nearby?lat=$lat&long=$lng&radius_km=$radius';
  }
  
  // ==================== NEW ADMIN HELPER METHODS ====================
  
  // Admin endpoints helper methods
  static String buildAdminIssueDetailsUrl(int reportId) {
    return '$baseUrl/api/admin/issues/$reportId';
  }
  
  static String buildAdminUpdateStatusUrl(int reportId) {
    return '$baseUrl/api/admin/issues/$reportId/status';
  }
  
  static String buildAdminAssignDepartmentUrl(int reportId) {
    return '$baseUrl/api/admin/issues/$reportId/assign';
  }
  
  static String buildAdminDeleteIssueUrl(int reportId) {
    return '$baseUrl/api/admin/issues/$reportId';
  }
  
  static String buildAdminResolveIssueUrl(int reportId) {
    return '$baseUrl/api/admin/issues/$reportId/resolve';
  }
  
  static String buildAdminIssuesWithParams({String? status, String? department}) {
    String url = '$baseUrl/api/admin/issues';
    final params = <String>[];
    
    if (status != null) params.add('status=$status');
    if (department != null) params.add('department=$department');
    
    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }
    
    return url;
  }
}