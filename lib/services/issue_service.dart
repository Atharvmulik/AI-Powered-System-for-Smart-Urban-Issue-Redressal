import 'dart:convert';
import 'api_service.dart';
import '../config/api_config.dart';

class IssueService {
  final ApiService _apiService = ApiService();

  // Report an issue
  Future<Map<String, dynamic>> reportIssue({
    required String title,
    required String description,
    required String category,
    required String location,
    required double latitude,
    required double longitude,
    String? imagePath,
  }) async {
    try {
      // First, create the issue
      final response = await _apiService.post(
        ApiConfig.reportIssueEndpoint,
        {
          'title': title,
          'description': description,
          'category': category,
          'location': location,
          'latitude': latitude,
          'longitude': longitude,
          'status': 'pending',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        
        // If there's an image, upload it
        if (imagePath != null && data['id'] != null) {
          await _apiService.uploadImage(imagePath, data['id'].toString());
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

  // Get issues by user
  Future<Map<String, dynamic>> getUserIssues() async {
    try {
      final response = await _apiService.get('${ApiConfig.getIssuesEndpoint}/my-issues');

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