import 'dart:convert';
import 'api_service.dart';
import '../config/api_config.dart';

class IssueService {
  final ApiService _apiService = ApiService();

  // Report an issue - ✅ UPDATED to match backend schema
  Future<Map<String, dynamic>> reportIssue({
    required String title,
    required String description,
    required String issueType, // ✅ CHANGED from 'category' to 'issueType'
    required String user_name, // ✅ CHANGED from 'reporterName' to 'user_name'
    required String user_mobile, // ✅ CHANGED from 'reporterPhone' to 'user_mobile'
    required double location_lat, // ✅ CHANGED from 'latitude' to 'location_lat'
    required double location_long, // ✅ CHANGED from 'longitude' to 'location_long'
    String? user_email, // ✅ CHANGED from 'reporterEmail' to 'user_email'
    String? location_address, // ✅ ADDED this field
    String? imagePath,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.reportIssueEndpoint,
        {
          // User Information - ✅ UPDATED field names
          'user_name': user_name,
          'user_mobile': user_mobile,
          'user_email': user_email,
          
          // Issue Information - ✅ UPDATED field names
          'issue_type': issueType, // ✅ CHANGED from 'category'
          'title': title,
          'description': description,
          
          // Location Information - ✅ UPDATED field names
          'location_lat': location_lat,
          'location_long': location_long,
          'location_address': location_address,
          
          // ❌ REMOVED: 'urgency', 'status', 'category' (backend handles these)
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        
        // If there's an image, upload it
        if (imagePath != null && data['report_id'] != null) {
          await _apiService.uploadImage(imagePath, data['report_id'].toString());
        }
        
        return {'success': true, 'data': data};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'error': error['detail'] ?? 'Failed to report issue'};
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

  // Get issues by user - ❌ This endpoint might not exist in your backend
  Future<Map<String, dynamic>> getUserIssues() async {
    try {
      final response = await _apiService.get('/users/me/reports'); // ✅ Use correct endpoint

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
}