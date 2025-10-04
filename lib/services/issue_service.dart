import 'api_service.dart';

class IssueService {
  static const String baseUrl = 'http://10.0.2.2:3000/api'; // For Android emulator
  
  static final ApiService _api = ApiService();

  // Report a new issue
  static Future<Map<String, dynamic>> reportIssue({
    required String title,
    required String description,
    required String category,
    required String location,
    required String reporterName,
    required String reporterPhone,
    String? reporterEmail,
    String urgency = 'Medium',
  }) async {
    final data = {
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'reporterName': reporterName,
      'reporterPhone': reporterPhone,
      'reporterEmail': reporterEmail,
      'urgency': urgency,
      'status': 'submitted',
    };
    
    return await _api.post('$baseUrl/issues', data);
  }

  // Get all issues
  static Future<List<dynamic>> getIssues() async {
    return await _api.get('$baseUrl/issues');
  }

  // Get issue by ID
  static Future<Map<String, dynamic>> getIssueById(String id) async {
    return await _api.get('$baseUrl/issues/$id');
  }

  // Update issue status
  static Future<Map<String, dynamic>> updateIssueStatus(String id, String status) async {
    return await _api.post('$baseUrl/issues/$id/status', {'status': status});
  }
}