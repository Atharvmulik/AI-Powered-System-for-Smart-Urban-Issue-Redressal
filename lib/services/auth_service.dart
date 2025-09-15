// lib/services/auth_service.dart
import './api_service.dart';
import '../config/api_config.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiService.post(
        ApiConfig.login,
        {'email': email, 'password': password},
      );
      
      // Store token
      final token = response['access_token'];
      _apiService.setAuthToken(token);
      
      // Store token locally (using shared_preferences)
      // ...
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register(String email, String password, String name) async {
    try {
      final response = await _apiService.post(
        ApiConfig.register,
        {'email': email, 'password': password, 'name': name},
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}