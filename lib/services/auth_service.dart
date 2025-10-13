import 'dart:convert';
import 'api_service.dart';
import '../config/api_config.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  // Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiService.post(
        ApiConfig.loginEndpoint,
        {
          'email': email,
          'password': password,
          'is_admin': false, // ✅ ADDED
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['access_token'] != null) {
          _apiService.setToken(data['access_token']);
        }
        return {'success': true, 'data': data};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'error': error['detail'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Register user - ✅ UPDATED with name and phone
  Future<Map<String, dynamic>> register(
    String email, 
    String password, 
    String fullName, // ✅ ADDED
    String mobileNumber, // ✅ ADDED
  ) async {
    try {
      final response = await _apiService.post(
        ApiConfig.registerEndpoint,
        {
          'email': email,
          'password': password,
          'full_name': fullName, // ✅ ADDED
          'mobile_number': mobileNumber, // ✅ ADDED
          'is_admin': false, // ✅ ADDED
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'error': error['detail'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Logout user
  void logout() {
    _apiService.setToken(null);
  }
}