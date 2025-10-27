import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

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

  // ✅ CORRECTED: Generic POST method
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

  // ✅ CORRECTED: Generic GET method
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

  // ✅ CORRECTED: GET with query parameters
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