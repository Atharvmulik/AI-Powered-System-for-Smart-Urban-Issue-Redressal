import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../config/api_config.dart';

class IssueService {
  final ApiService _apiService = ApiService();

  // ✅ UPDATED: Submit report with urgency level instead of issue type
  Future<Map<String, dynamic>> submitReport(Map<String, dynamic> reportData) async {
    try {
      final response = await _apiService.post(
        ApiConfig.reportIssueEndpoint,
        {
          // User Information
          'user_name': reportData['user_name'],
          'user_mobile': reportData['user_mobile'],
          'user_email': reportData['user_email'],
          
          // ✅ CHANGED: urgency_level instead of issue_type
          'urgency_level': reportData['urgency_level'],
          'title': reportData['title'],
          'description': reportData['description'],
          
          // Location Information
          'location_lat': reportData['location_lat'],
          'location_long': reportData['location_long'],
          'location_address': reportData['location_address'],
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'error': error['detail'] ?? 'Failed to submit report'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ✅ ADDED: Get urgency levels from backend
  Future<Map<String, dynamic>> getUrgencyLevels() async {
    try {
      final response = await _apiService.get('/urgency-levels');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data['urgency_levels']};
      } else {
        return {'success': false, 'error': 'Failed to fetch urgency levels'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get all issues
  Future<Map<String, dynamic>> getIssues() async {
    try {
      final response = await _apiService.get(ApiConfig.getIssuesEndpoint);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to fetch issues'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get user issues
  Future<Map<String, dynamic>> getUserIssues() async {
    try {
      final response = await _apiService.get('/users/me/reports');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to fetch user issues'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ✅ ADDED: Upload image method
  Future<Map<String, dynamic>> uploadImage(String imagePath, String reportId) async {
    try {
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('${ApiConfig.baseUrl}/reports/$reportId/upload-image')
      );
      
      request.files.add(await http.MultipartFile.fromPath(
        'image', 
        imagePath
      ));
      
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final data = json.decode(responseData);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to upload image'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}