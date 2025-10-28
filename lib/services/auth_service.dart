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
    final isAdmin = adminEmails.contains(email.toLowerCase());
    print('🔍 Admin email check:');
    print('   - Input email: $email');
    print('   - Lowercase: ${email.toLowerCase()}');
    print('   - Admin emails list: $adminEmails');
    print('   - Is admin: $isAdmin');
    return isAdmin;
  }
  // Login user - CORRECTED VERSION
  Future<Map<String, dynamic>> login(String email, String password) async {
  try {
    print('🔐 Login attempt for: $email');
    print('👑 Is admin email: ${isAdminEmail(email)}');
    
    // Handle admin login completely in frontend (no API call for admin)
    if (isAdminEmail(email)) {
      print('👑 ADMIN EMAIL DETECTED - Checking password...');
      if (password == 'admin123') { 
        print('✅ ADMIN LOGIN SUCCESSFUL - Returning is_admin: true');
        return {
          'success': true,
          'is_admin': true,  // ← This MUST be true for admin
          'user_name': 'Admin User',
          'email': email,
        };
      } else {
        print('❌ ADMIN PASSWORD INCORRECT');
        return {
          'success': false,
          'error': 'Invalid admin password',
          'is_admin': false,
        };
      }
    }
    
    // Regular users go through backend API
    print('👤 Regular user - calling API');
    final response = await _apiService.post(
      ApiConfig.loginEndpoint,
      {
        'email': email,
        'password': password,
      },
    );

    print('📡 API Response Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('✅ Regular user login successful');
      print('📊 Response data: $data');
      
      if (data['access_token'] != null) {
        _apiService.setToken(data['access_token']);
      }
      
      return {
        'success': true, 
        'is_admin': data['is_admin'] ?? false, // Get from backend response
        'user_name': data['full_name'] ?? 'User',
        'email': email,
        'data': data,
      };
    } else {
      final error = json.decode(response.body);
      print('❌ Regular user login failed: ${error['detail']}');
      return {
        'success': false, 
        'error': error['detail'] ?? 'Login failed',
        'is_admin': false,
      };
    }
  } catch (e) {
    print('💥 Login error: $e');
    return {
      'success': false, 
      'error': 'Network error: Please check your connection',
      'is_admin': false,
    };
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
          'error': 'Admin accounts cannot be registered. Please use existing admin credentials.',
          'is_admin': false,
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
          'is_admin': false, // New registrations are always regular users
          'user_name': fullName,
          'email': email,
          'data': data,
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false, 
          'error': error['detail'] ?? 'Registration failed',
          'is_admin': false,
        };
      }
    } catch (e) {
      return {
        'success': false, 
        'error': e.toString(),
        'is_admin': false,
      };
    }
  }

  // Logout user
  void logout() {
    _apiService.setToken(null);
  }
}