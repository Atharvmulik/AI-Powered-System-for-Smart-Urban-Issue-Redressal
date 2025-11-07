import 'dart:convert';
import 'api_service.dart';
import '../config/api_config.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  
  // Define admin emails - ONLY these can access admin dashboard
  static const List<Map<String, String>> adminUsers = [
    {'email': 'atharv@civiceye.com', 'name': 'Admin Atharv'},
    {'email': 'siddhi@civiceye.com', 'name': 'Admin Sidhhi'},
    {'email': 'tejas@civiceye.com', 'name': 'Admin Tejas'},
    {'email': 'roshani@civiceye.com', 'name': 'Admin Roshani'},
    {'email': 'vaishnavi@civiceye.com', 'name': 'Admin Vaishnavi '},
  ];

  // Check if email is admin - CORRECTED
  bool isAdminEmail(String email) {
    final cleanEmail = email.toLowerCase().trim();
    final isAdmin = adminUsers.any((admin) => admin['email'] == cleanEmail);
    
    print('🔍 Admin email check:');
    print('   - Input email: $email');
    print('   - Clean email: $cleanEmail');
    print('   - Is admin: $isAdmin');
    
    return isAdmin;
  }

  // Get admin user details - CORRECTED
  static Map<String, String>? getAdminUser(String email) {
    final cleanEmail = email.toLowerCase().trim();
    for (var admin in adminUsers) {
      if (admin['email'] == cleanEmail) {
        return admin;
      }
    }
    return null;
  }

  // Get admin name by email
  String getAdminName(String email) {
    final admin = getAdminUser(email);
    return admin?['name'] ?? 'Admin User';
  }

  // Login user - CORRECTED VERSION
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('🔐 Login attempt for: $email');
      print('👑 Is admin email: ${isAdminEmail(email)}');
      
      // Handle admin login completely in frontend (no API call for admin)
      if (isAdminEmail(email)) {
        print('👑 ADMIN EMAIL DETECTED - Checking password...');
        
        // Simple admin password check
        if (password == 'admin123') { 
          final adminName = getAdminName(email);
          print('✅ ADMIN LOGIN SUCCESSFUL - Name: $adminName');
          
          return {
            'success': true,
            'is_admin': true,  // ← This MUST be true for admin
            'user_name': adminName,
            'email': email,
          };
        } else {
          print('❌ ADMIN PASSWORD INCORRECT');
          return {
            'success': false,
            'error': 'Invalid admin password. Use "admin123"',
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