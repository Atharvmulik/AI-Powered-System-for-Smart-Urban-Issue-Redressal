import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // ✅ This should be correct
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

  // Generic POST method
  Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final url = '$baseUrl$endpoint'; // This will now work correctly
      print('🌐 Making request to: $url'); // For debugging
      
      final response = await http.post(
        Uri.parse(url),
        headers: getHeaders(),
        body: json.encode(data),
      );
      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Generic GET method
  Future<http.Response> get(String endpoint) async {
    try {
      final url = '$baseUrl$endpoint';
      print('🌐 Making request to: $url'); // Add this for debugging
      
      final response = await http.get(
        Uri.parse(url),
        headers: getHeaders(),
      );
      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Upload image method
  Future<http.Response> uploadImage(String imagePath, String issueId) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl${ApiConfig.uploadImageEndpoint}'),
      );
      
      request.headers.addAll(getHeaders());
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        imagePath,
      ));
      request.fields['issue_id'] = issueId;

      var response = await request.send();
      return http.Response.fromStream(response);
    } catch (e) {
      throw Exception('Upload error: $e');
    }
  }
}