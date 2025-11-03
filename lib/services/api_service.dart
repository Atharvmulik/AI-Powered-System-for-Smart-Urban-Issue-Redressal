import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/admin_issue_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String baseUrl = ApiConfig.baseUrl;
  String? _token;

  // Set authentication token
  void setToken(String? token) {
    _token = token;
  }

  // Get headers with authentication
  Map<String, String> getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    
    return headers;
  }

// ==================== MAP ENDPOINTS ====================

// Get all issues with coordinates for map
Future<http.Response> getMapIssues({String? status, String? category}) async {
  final url = ApiConfig.buildMapIssuesUrl(status: status, category: category);
  return await get(url);
}

// Get issues within geographic bounds
Future<http.Response> getIssuesInBounds(double north, double south, double east, double west) async {
  final url = ApiConfig.buildMapIssuesInBoundsUrl(north, south, east, west);
  return await get(url);
}

// Get map statistics
Future<http.Response> getMapStats() async {
  final url = ApiConfig.buildMapStatsUrl();
  return await get(url);
}

  // ==================== EXISTING METHODS BELOW - NO CHANGES ====================

  // ✅ Generic POST method
  Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final url = '$baseUrl$endpoint';
      print('🌐 POST Request to: $url');
      print('📦 Request Data: $data');
      
      final response = await http.post(
        Uri.parse(url),
        headers: getHeaders(),
        body: json.encode(data),
      );
      
      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');
      
      return response;
    } catch (e) {
      print('❌ POST Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // ✅ Generic PATCH method
  Future<http.Response> patch(String endpoint, Map<String, dynamic> data) async {
    try {
      final url = '$baseUrl$endpoint';
      print('🌐 PATCH Request to: $url');
      print('📦 Request Data: $data');
      
      final response = await http.patch(
        Uri.parse(url),
        headers: getHeaders(),
        body: json.encode(data),
      );
      
      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');
      
      return response;
    } catch (e) {
      print('❌ PATCH Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // ✅ Generic GET method
  Future<http.Response> get(String endpoint) async {
    try {
      final url = '$baseUrl$endpoint';
      print('🌐 GET Request to: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: getHeaders(),
      );
      
      print('📡 Response Status: ${response.statusCode}');
      return response;
    } catch (e) {
      print('❌ GET Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // ✅ GET with query parameters
  Future<http.Response> getWithParams(String endpoint, Map<String, String> params) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: params);
      print('🌐 GET Request to: $uri');
      
      final response = await http.get(
        uri,
        headers: getHeaders(),
      );
      
      print('📡 Response Status: ${response.statusCode}');
      return response;
    } catch (e) {
      print('❌ GET Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // ==================== DEPARTMENT ANALYSIS ENDPOINTS ====================

  // Get departments summary
  Future<http.Response> getDepartmentsSummary({String period = 'month'}) async {
    return await getWithParams(ApiConfig.departmentsSummary, {
      'period': period,
    });
  }

  // Get department details
  Future<http.Response> getDepartmentDetails(int deptId, {String period = 'month'}) async {
    return await getWithParams('${ApiConfig.departmentDetails}/$deptId', {
      'period': period,
    });
  }

  // Get issues by department for bar chart
  Future<http.Response> getDepartmentIssues({String period = 'month'}) async {
    return await getWithParams(ApiConfig.departmentIssues, {
      'period': period,
    });
  }

  // Get resolution trends
  Future<http.Response> getResolutionTrends({String period = 'month'}) async {
    return await getWithParams(ApiConfig.resolutionTrends, {
      'period': period,
    });
  }

  // Get department efficiency trend
  Future<http.Response> getDepartmentEfficiencyTrend(int deptId, {int months = 6}) async {
    return await getWithParams('${ApiConfig.departmentEfficiencyTrend}/$deptId/efficiency-trend', {
      'months': months.toString(),
    });
  }

  // Submit department feedback
  Future<http.Response> submitDepartmentFeedback(int departmentId, String feedbackText, {int? rating, String? userName}) async {
    final data = {
      'department_id': departmentId,
      'feedback_text': feedbackText,
    };
    
    if (rating != null) data['rating'] = rating;
    if (userName != null) data['user_name'] = userName;
    
    return await post(ApiConfig.departmentFeedback, data);
  }

  // Update issues status in bulk
  Future<http.Response> updateIssuesStatus(int departmentId, List<int> issueIds, String newStatus) async {
    return await post(ApiConfig.updateIssuesStatus, {
      'department_id': departmentId,
      'issue_ids': issueIds,
      'new_status': newStatus,
    });
  }

  // ==================== ADMIN ENDPOINTS ====================

  // Get all issues for admin - UPDATED FOR STRING STATUS
  Future<http.Response> getAdminIssues({String? status, String? department}) async {
    final params = <String, String>{};
    if (status != null && status != 'all') params['status'] = status;
    if (department != null) params['department'] = department;
    
    return await getWithParams('/api/admin/issues', params);
  }

  // Get all admin issues as List<AdminIssue>
  Future<List<AdminIssue>> getAdminIssuesList({String? status, String? department}) async {
    try {
      final response = await getAdminIssues(status: status, department: department);
      
      print('🔍 Raw API Response: ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> issuesJson = data['issues'] ?? [];
        
        print('🔍 Number of issues received: ${issuesJson.length}');
        
        List<AdminIssue> issues = issuesJson.map((json) => AdminIssue.fromJson(json)).toList();
        return issues;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load issues: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Network Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // Get single issue details
  Future<http.Response> getAdminIssueDetails(int reportId) async {
    return await get('/api/admin/issues/$reportId');
  }

  // Update issue status - UPDATED FOR STRING STATUS
  Future<http.Response> updateIssueStatus(int reportId, String status) async {
    return await patch('/api/admin/issues/$reportId/status', {
      'status': status,
    });
  }

  // Assign issue to department - UPDATED FOR STRING STATUS
  Future<http.Response> assignToDepartment(int reportId, String department) async {
    return await patch('/api/admin/issues/$reportId/assign', {
      'department': department,
    });
  }

  // Delete issue
  Future<http.Response> deleteIssue(int reportId) async {
    try {
      final url = '$baseUrl/api/admin/issues/$reportId';
      print('🌐 DELETE Request to: $url');
      
      final response = await http.delete(
        Uri.parse(url),
        headers: getHeaders(),
      );
      
      print('📡 Response Status: ${response.statusCode}');
      return response;
    } catch (e) {
      print('❌ DELETE Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // Resolve issue - UPDATED FOR STRING STATUS
  Future<http.Response> resolveIssue(int reportId, String resolutionNotes, String resolvedBy) async {
    return await post('/api/admin/issues/$reportId/resolve', {
      'resolution_notes': resolutionNotes,
      'resolved_by': resolvedBy,
    });
  }

  // Get all departments
  Future<http.Response> getDepartments() async {
    return await get('/api/admin/departments');
  }

  // Update these methods in your ApiService class

  // Get user profile by email (NO AUTH REQUIRED)
  Future<http.Response> getUserProfileByEmail(String email) async {
    return await getWithParams('/api/users/profile', {
      'email': email,
    });
  }

  // Update user profile by email (NO AUTH REQUIRED)
  Future<http.Response> updateUserProfile(String email, Map<String, dynamic> profileData) async {
    return await putWithParams('/api/users/profile', profileData, {
      'email': email,
    });
  }

  // Add this PUT with parameters method
  Future<http.Response> putWithParams(String endpoint, Map<String, dynamic> data, Map<String, String> params) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: params);
      print('🌐 PUT Request to: $uri');
      print('📦 Request Data: $data');
      
      final response = await http.put(
        uri,
        headers: getHeaders(),
        body: json.encode(data),
      );
      
      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');
      
      return response;
    } catch (e) {
      print('❌ PUT Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // ==================== EXISTING ENDPOINTS ====================

  Future<http.Response> register(String email, String password, String fullName, String mobileNumber) async {
    return await post(ApiConfig.registerEndpoint, {
      'email': email,
      'password': password,
      'full_name': fullName,
      'mobile_number': mobileNumber,
      'is_admin': false,
    });
  }

  // Dashboard Data (PUBLIC - no auth required)
  Future<http.Response> getDashboardSummary() async {
    return await get(ApiConfig.dashboardSummary);
  }

  Future<http.Response> getDashboardStats() async {
    return await get(ApiConfig.dashboardStats);
  }

  Future<http.Response> getTodayActivity() async {
    return await get(ApiConfig.todayActivity);
  }

  Future<http.Response> getTodayResolved() async {
    return await get(ApiConfig.todayResolved);
  }

  Future<http.Response> getCategorySummary() async {
    return await get(ApiConfig.categorySummary);
  }

  // 1. NEW - For dashboard
  Future<http.Response> getUserReportsForDashboard(String userEmail) async {
    return await getWithParams('/users/reports/filtered', {
      'user_email': userEmail,
      'status_filter': 'all',
    });
  }

  // 2. NEW - For filtering
  Future<http.Response> getUserReports(String userEmail, {String statusFilter = 'all'}) async {
    return await getWithParams('/users/reports/filtered', {
      'user_email': userEmail,
      'status_filter': statusFilter,
    });
  }

  // Nearby Issues (PUBLIC)
  Future<http.Response> getNearbyIssues(double lat, double lng, {double radius = 5.0}) async {
    return await getWithParams(ApiConfig.nearbyIssues, {
      'lat': lat.toString(),
      'long': lng.toString(),
      'radius_km': radius.toString(),
    });
  }

  // User Complaints (PUBLIC - uses user_email parameter)
  Future<http.Response> getUserReportsFiltered(String userEmail, {String statusFilter = 'all'}) async {
    return await getWithParams(ApiConfig.userReportsFiltered, {
      'user_email': userEmail,
      'status_filter': statusFilter,
    });
  }

  Future<http.Response> searchUserReports(String userEmail, String query) async {
    return await getWithParams(ApiConfig.userReportsSearch, {
      'user_email': userEmail,
      'query': query,
    });
  }

  // Complaint Details (PUBLIC)
  Future<http.Response> getReportTimeline(int reportId) async {
    return await get('${ApiConfig.reportTimeline}/$reportId/timeline');
  }

  // Reference Data (PUBLIC)
  Future<http.Response> getCategories() async {
    return await get(ApiConfig.categories);
  }

  Future<http.Response> getUrgencyLevels() async {
    return await get(ApiConfig.urgencyLevels);
  }

  Future<http.Response> getStatuses() async {
    return await get(ApiConfig.statuses);
  }

  // Create Report (may require auth depending on your implementation)
  Future<http.Response> createReport(Map<String, dynamic> reportData) async {
    return await post(ApiConfig.createReport, reportData);
  }

  // Confirm Issue (may require auth)
  Future<http.Response> confirmIssue(int reportId) async {
    return await post('${ApiConfig.confirmIssue}/$reportId/confirm', {});
  }

  // User Profile (AUTH REQUIRED)
  Future<http.Response> getUserProfile() async {
    return await get(ApiConfig.userProfile);
  }

  // Get all reports (for admin or public listing)
  Future<http.Response> getAllReports({int skip = 0, int limit = 100}) async {
    return await getWithParams(ApiConfig.getIssuesEndpoint, {
      'skip': skip.toString(),
      'limit': limit.toString(),
    });
  }

  // Get specific report
  Future<http.Response> getReport(int reportId) async {
    return await get('${ApiConfig.getIssuesEndpoint}$reportId');
  }

  // ✅ Helper method to parse response
  static Map<String, dynamic> parseResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Request failed with status: ${response.statusCode}. ${response.body}');
    }
  }

  // ✅ Helper method to check if response is successful
  static bool isSuccess(http.Response response) {
    return response.statusCode >= 200 && response.statusCode < 300;
  }
}