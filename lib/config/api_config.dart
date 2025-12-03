import 'env.dart';

class ApiConfig {
  static const String baseUrl = Env.apiBaseUrl;
  
  // ==================== MAP ENDPOINTS ====================
  
  // Map endpoints
  static String get mapIssues => "/api/admin/map/issues";
  static String get mapIssuesInBounds => "/api/admin/map/issues-in-bounds";
  static String get mapStats => "/api/admin/map/stats";
  
  // ✅ CORRECTED: Exact endpoints from your FastAPI backend
  static const String loginEndpoint = '/login';
  static const String registerEndpoint = '/api/users/register'; 
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
  static String get reportTimeline => "/reports"; 
  
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
  
  // ==================== DEPARTMENT ANALYSIS ENDPOINTS ====================
  
  // Department Analysis
  static String get departmentsSummary => "/api/departments/summary";
  static String get departmentDetails => "/api/departments"; // /{dept_id}
  static String get departmentIssues => "/api/departments/issues/by-department";
  static String get resolutionTrends => "/api/departments/resolution-trends";
  static String get departmentEfficiencyTrend => "/api/departments"; // /{dept_id}/efficiency-trend
  static String get departmentFeedback => "/api/departments/feedback";
  static String get updateIssuesStatus => "/api/departments/update-issues-status";

  // ==================== ADMIN DASHBOARD ENDPOINTS ====================
  static const String adminDashboardStats = "/api/admin/dashboard/stats";
  static const String adminMonthlyTrends = "/api/admin/dashboard/monthly-trends";
  static const String adminDepartmentPerformance = "/api/admin/dashboard/department-performance";
  static const String adminRecentReports = "/api/admin/dashboard/recent-reports";
  static const String adminRecentActivity = "/api/admin/dashboard/recent-activity";
  static const String adminCategoryBreakdown = "/api/admin/dashboard/category-breakdown";
  
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
  
  // ==================== MAP HELPER METHODS ====================
  
  static String buildMapIssuesUrl({String? status, String? category}) {
    String url = mapIssues; // Just the endpoint path
    final params = <String>[];
    
    if (status != null && status != 'all') params.add('status=$status');
    if (category != null && category != 'all') params.add('category=$category');
    
    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }
    
    return url; // Returns: "/api/admin/map/issues?status=pending"
  }

  static String buildMapIssuesInBoundsUrl(double north, double south, double east, double west) {
    return '$mapIssuesInBounds?north=$north&south=$south&east=$east&west=$west';
  }

  static String buildMapStatsUrl() {
    return mapStats;
  }
  
  // ==================== EXISTING HELPER METHODS ====================
  
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
  
  // ==================== NEW DEPARTMENT ANALYSIS HELPER METHODS ====================
  
  // Department analysis helper methods
  static String buildDepartmentDetailsUrl(int deptId) {
    return '$baseUrl/api/departments/$deptId';
  }
  
  static String buildDepartmentEfficiencyTrendUrl(int deptId, {int months = 6}) {
    return '$baseUrl/api/departments/$deptId/efficiency-trend?months=$months';
  }
  
  static String buildDepartmentIssuesUrl({String period = 'month'}) {
    return '$baseUrl/api/departments/issues/by-department?period=$period';
  }
  
  static String buildResolutionTrendsUrl({String period = 'month'}) {
    return '$baseUrl/api/departments/resolution-trends?period=$period';
  }
  
  static String buildDepartmentsSummaryUrl({String period = 'month'}) {
    return '$baseUrl/api/departments/summary?period=$period';
  }

  // ==================== USER PROFILE ENDPOINTS ====================
  static const String userProfileByEmail = '/api/users/profile';
  static const String updateUserProfile = '/api/users/profile';
  static const String updateCurrentUserProfile = '/users/me';

  // Helper methods for user profile
  static String buildUserProfileByEmailUrl(String email) {
    return '$baseUrl$userProfileByEmail?email=$email';
  }

  static String buildUpdateUserProfileUrl() {
    return '$baseUrl$updateUserProfile';
  }

  static String buildUpdateCurrentUserProfileUrl() {
    return '$baseUrl$updateCurrentUserProfile';
  }
  
  // ==================== ADMIN DASHBOARD HELPER METHODS ====================
  
  static String buildAdminDashboardStatsUrl() {
    return '$baseUrl$adminDashboardStats';
  }
  
  static String buildAdminMonthlyTrendsUrl() {
    return '$baseUrl$adminMonthlyTrends';
  }
  
  static String buildAdminDepartmentPerformanceUrl() {
    return '$baseUrl$adminDepartmentPerformance';
  }
  
  static String buildAdminRecentReportsUrl({int limit = 4}) {
    return '$baseUrl$adminRecentReports?limit=$limit';
  }
  
  static String buildAdminRecentActivityUrl() {
    return '$baseUrl$adminRecentActivity';
  }
  
  static String buildAdminCategoryBreakdownUrl() {
    return '$baseUrl$adminCategoryBreakdown';
  }

  // ==================== AI PREDICTION ENDPOINTS ====================
  static String get predictDepartment => "/predict-department";
  static String get predictTextOnly => "/predict-text-only";
  static String get predictImage => "/predict-image";
  
  // Helper methods for AI endpoints
  static String buildPredictDepartmentUrl() {
    return '$baseUrl$predictDepartment';
  }
  
  static String buildPredictTextOnlyUrl() {
    return '$baseUrl$predictTextOnly';
  }
  
  static String buildPredictImageUrl() {
    return '$baseUrl$predictImage';
  }

  // ==================== AI AUTO-ASSIGNMENT ENDPOINTS ====================
  static String get aiAutoAssign => "/api/ai/auto-assign";
  static String get aiAssignmentStatus => "/api/ai/assignment-status";
  static String get aiAutoAssignedIssues => "/api/ai/auto-assigned-issues";

  // Helper methods for AI auto-assignment
  static String buildAIAutoAssignUrl() {
    return '$baseUrl$aiAutoAssign';
  }

  static String buildAIAssignmentStatusUrl() {
    return '$baseUrl$aiAssignmentStatus';
  }

  static String buildAIAutoAssignedIssuesUrl(String department, {String period = 'month'}) {
    return '$baseUrl$aiAutoAssignedIssues?department=$department&period=$period';
  }
}