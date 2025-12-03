// lib/config/env.dart

class Env {
  // App information
  static const String appName = 'Urban Issue Redressal';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'AI-Powered System for Smart Urban Issue Redressal';
  
  // API configuration
  static const String apiBaseUrl =  "https://ai-powered-system-for-smart-urban-issue.onrender.com"; 
  // Debug mode
  static const bool debug = true;
  
  // Feature flags
  static const bool enableAiPredictions = true;
  static const bool enableImageUpload = true;
  static const bool enableNotifications = true;
  
  // Default settings
  static const int defaultPageSize = 20;
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  
  // Supported image formats
  static const List<String> supportedImageFormats = [
    'image/jpeg',
    'image/png',
    'image/jpg'
  ];
  
  // App colors
  static const int primaryColor = 0xFF2C3E50;
  static const int accentColor = 0xFF3498DB;
  static const int successColor = 0xFF2ECC71;
  static const int warningColor = 0xFFF39C12;
  static const int errorColor = 0xFFE74C3C;
  
  // Get app info as a map
  static Map<String, dynamic> get appInfo {
    return {
      'name': appName,
      'version': appVersion,
      'description': appDescription,
    };
  }
  
  // Check if debug mode is enabled
  static bool get isDebugMode {
    return debug;
  }
}