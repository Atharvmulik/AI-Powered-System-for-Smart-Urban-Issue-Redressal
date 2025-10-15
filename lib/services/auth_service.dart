import 'dart:convert';
import 'api_service.dart';
import '../config/api_config.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  
  // Define admin emails - ONLY these can access admin dashboard
  static const List<String> adminEmails = [
    'admin1@civiceye.com',
    'admin2@civiceye.com', 
    'admin3@civiceye.com',
    'admin4@civiceye.com',
    'vaishnavi@civiceye.com'
  ];

  // Check if email is admin
  bool isAdminEmail(String email) {
    return adminEmails.contains(email.toLowerCase());
  }

  // Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final bool isAdmin = isAdminEmail(email);
      
      final response = await _apiService.post(
        ApiConfig.loginEndpoint,
        {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['access_token'] != null) {
          _apiService.setToken(data['access_token']);
        }
        return {
          'success': true, 
          'data': data, 
          'is_admin': isAdmin // Determine admin status locally
        };
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'error': error['detail'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Register user - REGULAR USERS ONLY
  Future<Map<String, dynamic>> register(
    String email, 
    String password, 
    String fullName,
    String mobileNumber,
  ) async {
    try {
      // Check if trying to register with admin email
      if (isAdminEmail(email)) {
        return {
          'success': false, 
          'error': 'Admin accounts cannot be registered. Please use existing admin credentials.'
        };
      }
      
      final response = await _apiService.post(
        ApiConfig.registerEndpoint,
        {
          'email': email,
          'password': password,
          'full_name': fullName,
          'mobile_number': mobileNumber,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true, 
          'data': data, 
          'is_admin': false // Regular users only
        };
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