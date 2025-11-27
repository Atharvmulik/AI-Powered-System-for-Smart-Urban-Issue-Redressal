import 'dart:convert';
import 'dart:io';
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
    final headers = {'Content-Type': 'application/json'};

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
  Future<http.Response> getIssuesInBounds(
    double north,
    double south,
    double east,
    double west,
  ) async {
    final url = ApiConfig.buildMapIssuesInBoundsUrl(north, south, east, west);
    return await get(url);
  }

  // Get map statistics
  Future<http.Response> getMapStats() async {
    final url = ApiConfig.buildMapStatsUrl();
    return await get(url);
  }

  // ==================== CORE HTTP METHODS ====================

  // Generic POST method
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

  // Generic PATCH method
  Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
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

  // Generic GET method
  Future<http.Response> get(String endpoint) async {
    try {
      final url = '$baseUrl$endpoint';
      print('🌐 GET Request to: $url');

      final response = await http.get(Uri.parse(url), headers: getHeaders());

      print('📡 Response Status: ${response.statusCode}');
      return response;
    } catch (e) {
      print('❌ GET Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // GET with query parameters
  Future<http.Response> getWithParams(
    String endpoint,
    Map<String, String> params,
  ) async {
    try {
      final uri = Uri.parse(
        '$baseUrl$endpoint',
      ).replace(queryParameters: params);
      print('🌐 GET Request to: $uri');

      final response = await http.get(uri, headers: getHeaders());

      print('📡 Response Status: ${response.statusCode}');
      return response;
    } catch (e) {
      print('❌ GET Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // PUT with parameters method
  Future<http.Response> putWithParams(
    String endpoint,
    Map<String, dynamic> data,
    Map<String, String> params,
  ) async {
    try {
      final uri = Uri.parse(
        '$baseUrl$endpoint',
      ).replace(queryParameters: params);
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

  // In api_service.dart - Fix these methods:

  // Get monthly trends data
  Future<http.Response> getMonthlyTrends() async {
    return await get(ApiConfig.adminMonthlyTrends);
  }

  // Get department performance data
  Future<http.Response> getDepartmentPerformance() async {
    return await get(ApiConfig.adminDepartmentPerformance);
  }

  // Get recent reports for dashboard
  Future<http.Response> getRecentReports({int limit = 4}) async {
    return await getWithParams(ApiConfig.adminRecentReports, {
      'limit': limit.toString(),
    });
  }

  // ==================== AI AUTO-ASSIGNMENT ENDPOINTS ====================

  // Trigger AI auto-assignment for unassigned issues
  Future<http.Response> triggerAIAssignment({
    bool forceReassign = false,
    String priority = 'medium',
  }) async {
    try {
      final response = await post('/api/ai/auto-assign', {
        'force_reassign': forceReassign,
        'priority': priority,
      });

      print('🤖 AI Assignment Response: ${response.statusCode}');
      return response;
    } catch (e) {
      print('❌ AI Assignment error: $e');
      return http.Response('Error: $e', 500);
    }
  }

  // Get AI assignment status and statistics
  Future<http.Response> getAIAssignmentStatus() async {
    try {
      final response = await get('/api/ai/assignment-status');
      return response;
    } catch (e) {
      print('❌ AI Assignment status error: $e');
      return http.Response('Error: $e', 500);
    }
  }

  // Get auto-assigned issues for a specific department
  Future<http.Response> getAutoAssignedIssues(
    String department, {
    String period = 'month',
  }) async {
    try {
      final response = await getWithParams('/api/ai/auto-assigned-issues', {
        'department': department,
        'period': period,
      });
      return response;
    } catch (e) {
      print('❌ Auto-assigned issues error: $e');
      return http.Response('Error: $e', 500);
    }
  }

  // ==================== AI PREDICTION METHODS ====================

  Future<Map<String, dynamic>> predictDepartment({
    required String description,
    String? imagePath,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/predict-department'),
      );

      // Add description field
      request.fields['description'] = description;

      // Add image file if provided
      if (imagePath != null && await File(imagePath).exists()) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imagePath),
        );
      }

      // Add headers (remove Content-Type for multipart)
      final headers = Map<String, String>.from(getHeaders());
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      print(
        '🤖 AI Prediction Request - Text: $description, Image: ${imagePath != null}',
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      print(
        '🤖 AI Prediction Response: ${response.statusCode} - $responseData',
      );

      if (response.statusCode == 200) {
        return json.decode(responseData);
      } else {
        throw Exception('AI prediction failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ AI Prediction Error: $e');
      throw Exception('AI prediction failed: $e');
    }
  }

  /// Predict department from text only
  Future<Map<String, dynamic>> predictTextOnly(String description) async {
    try {
      final response = await post('/predict-text-only', {
        'description': description,
      });

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Text prediction failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Text Prediction Error: $e');
      throw Exception('Text prediction failed: $e');
    }
  }

  Future<http.Response> createReportWithAutoDepartment(
    Map<String, dynamic> reportData, {
    String? imagePath,
  }) async {
    try {
      final String description = reportData['description'] ?? '';

      // Step 1: Get AI prediction for department
      print('🤖 Step 1: Getting AI prediction...');
      final prediction = await predictDepartment(
        description: description,
        imagePath: imagePath,
      );

      print('🎯 AI Prediction Result: ${prediction['final_department']}');
      print('📊 Confidence: ${prediction['final_confidence']}%');

      // Step 2: ✅ FIXED: Update reportData with prediction results
      final enhancedReportData = Map<String, dynamic>.from(reportData);
      enhancedReportData['department'] =
          prediction['final_department'] ?? 'other';
      enhancedReportData['auto_assigned'] = true;
      enhancedReportData['prediction_confidence'] =
          prediction['final_confidence'];

      print('📦 Enhanced Report Data: $enhancedReportData');

      // Step 3: Create report with enhanced data
      print('📤 Step 2: Creating report with AI-assigned department...');
      return await post(ApiConfig.createReport, enhancedReportData);
    } catch (e) {
      print('⚠️ Auto-department assignment failed: $e');

      // Fallback: Create report without auto-assignment
      final fallbackData = Map<String, dynamic>.from(reportData);
      fallbackData['department'] = 'other';
      fallbackData['auto_assigned'] = false;
      fallbackData['prediction_confidence'] = null;

      print('📤 Fallback: Creating report without AI assignment');
      return await post(ApiConfig.createReport, fallbackData);
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
  Future<http.Response> getDepartmentDetails(
    int deptId, {
    String period = 'month',
  }) async {
    return await getWithParams('${ApiConfig.departmentDetails}/$deptId', {
      'period': period,
    });
  }

  // Get issues by department for bar chart
  Future<http.Response> getDepartmentIssues({String period = 'month'}) async {
    return await getWithParams(ApiConfig.departmentIssues, {'period': period});
  }

  // Get resolution trends
  Future<http.Response> getResolutionTrends({String period = 'month'}) async {
    return await getWithParams(ApiConfig.resolutionTrends, {'period': period});
  }

  // Get department efficiency trend
  Future<http.Response> getDepartmentEfficiencyTrend(
    int deptId, {
    int months = 6,
  }) async {
    return await getWithParams(
      '${ApiConfig.departmentEfficiencyTrend}/$deptId/efficiency-trend',
      {'months': months.toString()},
    );
  }

  // Submit department feedback
  Future<http.Response> submitDepartmentFeedback(
    int departmentId,
    String feedbackText, {
    int? rating,
    String? userName,
  }) async {
    final data = {'department_id': departmentId, 'feedback_text': feedbackText};

    if (rating != null) data['rating'] = rating;
    if (userName != null) data['user_name'] = userName;

    return await post(ApiConfig.departmentFeedback, data);
  }

  // Update issues status in bulk
  Future<http.Response> updateIssuesStatus(
    int departmentId,
    List<int> issueIds,
    String newStatus,
  ) async {
    return await post(ApiConfig.updateIssuesStatus, {
      'department_id': departmentId,
      'issue_ids': issueIds,
      'new_status': newStatus,
    });
  }

  Future<http.Response> getAdminDashboardStats() async {
    return await get(ApiConfig.adminDashboardStats);
  }

  // Get recent activity for admin dashboard
  Future<http.Response> getAdminRecentActivity() async {
    return await get(ApiConfig.adminRecentActivity);
  }

  // Get category breakdown for admin dashboard
  Future<http.Response> getAdminCategoryBreakdown() async {
    return await get(ApiConfig.adminCategoryBreakdown);
  }

  // ==================== ADMIN ENDPOINTS ====================

  // Get all issues for admin - UPDATED FOR STRING STATUS
  Future<http.Response> getAdminIssues({
    String? status,
    String? department,
  }) async {
    final params = <String, String>{};
    if (status != null && status != 'all') params['status'] = status;
    if (department != null) params['department'] = department;

    return await getWithParams('/api/admin/issues', params);
  }

  // Get all admin issues as List<AdminIssue>
  Future<List<AdminIssue>> getAdminIssuesList({
    String? status,
    String? department,
  }) async {
    try {
      final response = await getAdminIssues(
        status: status,
        department: department,
      );

      print('🔍 Raw API Response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> issuesJson = data['issues'] ?? [];

        print('🔍 Number of issues received: ${issuesJson.length}');

        List<AdminIssue> issues = issuesJson
            .map((json) => AdminIssue.fromJson(json))
            .toList();
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
  Future<http.Response> assignToDepartment(
    int reportId,
    String department,
  ) async {
    return await patch('/api/admin/issues/$reportId/assign', {
      'department': department,
    });
  }

  // Delete issue
  Future<http.Response> deleteIssue(int reportId) async {
    try {
      final url = '$baseUrl/api/admin/issues/$reportId';
      print('🌐 DELETE Request to: $url');

      final response = await http.delete(Uri.parse(url), headers: getHeaders());

      print('📡 Response Status: ${response.statusCode}');
      return response;
    } catch (e) {
      print('❌ DELETE Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // Resolve issue - UPDATED FOR STRING STATUS
  Future<http.Response> resolveIssue(
    int reportId,
    String resolutionNotes,
    String resolvedBy,
  ) async {
    return await post('/api/admin/issues/$reportId/resolve', {
      'resolution_notes': resolutionNotes,
      'resolved_by': resolvedBy,
    });
  }

  // Get all departments
  Future<http.Response> getDepartments() async {
    return await get('/api/admin/departments');
  }

  // Get user profile by email (NO AUTH REQUIRED)
  Future<http.Response> getUserProfileByEmail(String email) async {
    return await getWithParams('/api/users/profile', {'email': email});
  }

  // Update user profile by email (NO AUTH REQUIRED)
  Future<http.Response> updateUserProfile(
    String email,
    Map<String, dynamic> profileData,
  ) async {
    return await putWithParams('/api/users/profile', profileData, {
      'email': email,
    });
  }

  // ==================== AUTHENTICATION ENDPOINTS ====================

  Future<http.Response> login(String email, String password) async {
    return await post(ApiConfig.loginEndpoint, {
      'email': email,
      'password': password,
    });
  }

  Future<http.Response> register(
    String email,
    String password,
    String fullName,
    String mobileNumber,
  ) async {
    return await post(ApiConfig.registerEndpoint, {
      'email': email,
      'password': password,
      'full_name': fullName,
      'mobile_number': mobileNumber,
      'is_admin': false,
    });
  }

  // ==================== DASHBOARD ENDPOINTS ====================

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

  // For dashboard
  Future<http.Response> getUserReportsForDashboard(String userEmail) async {
    return await getWithParams('/users/reports/filtered', {
      'user_email': userEmail,
      'status_filter': 'all',
    });
  }

  // For filtering
  Future<http.Response> getUserReports(
    String userEmail, {
    String statusFilter = 'all',
  }) async {
    return await getWithParams('/users/reports/filtered', {
      'user_email': userEmail,
      'status_filter': statusFilter,
    });
  }

  // Nearby Issues (PUBLIC)
  Future<http.Response> getNearbyIssues(
    double lat,
    double lng, {
    double radius = 5.0,
  }) async {
    return await getWithParams(ApiConfig.nearbyIssues, {
      'lat': lat.toString(),
      'long': lng.toString(),
      'radius_km': radius.toString(),
    });
  }

  // User Complaints (PUBLIC - uses user_email parameter)
  Future<http.Response> getUserReportsFiltered(
    String userEmail, {
    String statusFilter = 'all',
  }) async {
    return await getWithParams(ApiConfig.userReportsFiltered, {
      'user_email': userEmail,
      'status_filter': statusFilter,
    });
  }

  Future<http.Response> searchUserReports(
    String userEmail,
    String query,
  ) async {
    return await getWithParams(ApiConfig.userReportsSearch, {
      'user_email': userEmail,
      'query': query,
    });
  }

  // Complaint Details (PUBLIC)
  Future<http.Response> getReportTimeline(int reportId) async {
    return await get('${ApiConfig.reportTimeline}/$reportId/timeline');
  }

  // ==================== REFERENCE DATA ENDPOINTS ====================

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

  // ==================== REPORT ENDPOINTS ====================

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

  // ==================== HELPER METHODS ====================

  // Helper method to parse response
  static Map<String, dynamic> parseResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception(
        'Request failed with status: ${response.statusCode}. ${response.body}',
      );
    }
  }

  // Helper method to check if response is successful
  static bool isSuccess(http.Response response) {
    return response.statusCode >= 200 && response.statusCode < 300;
  }
}
