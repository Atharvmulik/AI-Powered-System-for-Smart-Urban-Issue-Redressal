import 'dart:convert';
// import 'package:http/http.dart' as http;
import 'api_service.dart';
// import '../config/api_config.dart';

class IssueService {
  final ApiService _apiService = ApiService();

  // ✅ CORRECTED: Submit report with urgency level
  Future<Map<String, dynamic>> submitReport(Map<String, dynamic> reportData) async {
    try {
      final response = await _apiService.createReport({
        // User Information
        'user_name': reportData['user_name'],
        'user_mobile': reportData['user_mobile'],
        'user_email': reportData['user_email'],
        
        // ✅ CORRECT: urgency_level instead of issue_type
        'urgency_level': reportData['urgency_level'],
        'title': reportData['title'],
        'description': reportData['description'],
        
        // Location Information
        'location_lat': reportData['location_lat'],
        'location_long': reportData['location_long'],
        'location_address': reportData['location_address'],
      });

      if (ApiService.isSuccess(response)) {
        final data = ApiService.parseResponse(response);
        return {'success': true, 'data': data};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'error': error['detail'] ?? 'Failed to submit report'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ✅ CORRECTED: Get urgency levels from backend
  Future<Map<String, dynamic>> getUrgencyLevels() async {
    try {
      final response = await _apiService.getUrgencyLevels();

      if (ApiService.isSuccess(response)) {
        final data = ApiService.parseResponse(response);
        return {'success': true, 'data': data['urgency_levels']};
      } else {
        return {'success': false, 'error': 'Failed to fetch urgency levels'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ✅ CORRECTED: Get all issues (PUBLIC)
  Future<Map<String, dynamic>> getIssues({int skip = 0, int limit = 100}) async {
    try {
      final response = await _apiService.getAllReports(skip: skip, limit: limit);

      if (ApiService.isSuccess(response)) {
        final data = ApiService.parseResponse(response);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to fetch issues'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ✅ CORRECTED: Get user issues using user_email parameter (PUBLIC)
  Future<Map<String, dynamic>> getUserIssues(String userEmail, {String statusFilter = 'all'}) async {
    try {
      final response = await _apiService.getUserReportsFiltered(userEmail, statusFilter: statusFilter);

      if (ApiService.isSuccess(response)) {
        final data = ApiService.parseResponse(response);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to fetch user issues'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ✅ CORRECTED: Search user issues (PUBLIC)
  Future<Map<String, dynamic>> searchUserIssues(String userEmail, String query) async {
    try {
      final response = await _apiService.searchUserReports(userEmail, query);

      if (ApiService.isSuccess(response)) {
        final data = ApiService.parseResponse(response);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to search issues'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ✅ CORRECTED: Get report timeline (PUBLIC)
  Future<Map<String, dynamic>> getReportTimeline(int reportId) async {
    try {
      final response = await _apiService.getReportTimeline(reportId);

      if (ApiService.isSuccess(response)) {
        final data = ApiService.parseResponse(response);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to fetch report timeline'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ✅ CORRECTED: Get categories (PUBLIC)
  Future<Map<String, dynamic>> getCategories() async {
    try {
      final response = await _apiService.getCategories();

      if (ApiService.isSuccess(response)) {
        final data = ApiService.parseResponse(response);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to fetch categories'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ✅ CORRECTED: Get statuses (PUBLIC)
  Future<Map<String, dynamic>> getStatuses() async {
    try {
      final response = await _apiService.getStatuses();

      if (ApiService.isSuccess(response)) {
        final data = ApiService.parseResponse(response);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to fetch statuses'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ✅ CORRECTED: Get nearby issues (PUBLIC)
  Future<Map<String, dynamic>> getNearbyIssues(double lat, double lng, {double radius = 5.0}) async {
    try {
      final response = await _apiService.getNearbyIssues(lat, lng, radius: radius);

      if (ApiService.isSuccess(response)) {
        final data = ApiService.parseResponse(response);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to fetch nearby issues'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ✅ CORRECTED: Confirm issue (may require auth)
  Future<Map<String, dynamic>> confirmIssue(int reportId) async {
    try {
      final response = await _apiService.confirmIssue(reportId);

      if (ApiService.isSuccess(response)) {
        final data = ApiService.parseResponse(response);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to confirm issue'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ✅ CORRECTED: Get dashboard summary (PUBLIC)
  Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      final response = await _apiService.getDashboardSummary();

      if (ApiService.isSuccess(response)) {
        final data = ApiService.parseResponse(response);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to fetch dashboard summary'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ✅ CORRECTED: Get dashboard stats (PUBLIC)
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _apiService.getDashboardStats();

      if (ApiService.isSuccess(response)) {
        final data = ApiService.parseResponse(response);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to fetch dashboard stats'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ✅ CORRECTED: Get today's activity (PUBLIC)
  Future<Map<String, dynamic>> getTodayActivity() async {
    try {
      final response = await _apiService.getTodayActivity();

      if (ApiService.isSuccess(response)) {
        final data = ApiService.parseResponse(response);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to fetch today\'s activity'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ✅ CORRECTED: Get today's resolved issues (PUBLIC)
  Future<Map<String, dynamic>> getTodayResolved() async {
    try {
      final response = await _apiService.getTodayResolved();

      if (ApiService.isSuccess(response)) {
        final data = ApiService.parseResponse(response);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to fetch today\'s resolved issues'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ✅ CORRECTED: Get category summary (PUBLIC)
  Future<Map<String, dynamic>> getCategorySummary() async {
    try {
      final response = await _apiService.getCategorySummary();

      if (ApiService.isSuccess(response)) {
        final data = ApiService.parseResponse(response);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to fetch category summary'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}