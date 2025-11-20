import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class OpenWeatherLocationService {
  static const String apiKey = 'e60aa95d14bf10cc8a3d5cfff82bb352'; 
  static const String baseUrl = 'http://api.openweathermap.org/geo/1.0/direct';

  static Future<LocationResult> getLocationByCity(String cityName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?q=$cityName&limit=1&appid=$apiKey'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        if (data.isNotEmpty) {
          final location = data[0];
          return LocationResult(
            success: true,
            latitude: location['lat'],
            longitude: location['lon'],
            address: "${location['name']}, ${location['state'] ?? ''}, ${location['country']}",
          );
        } else {
          return LocationResult(
            success: false,
            error: 'City not found: $cityName',
          );
        }
      } else {
        return LocationResult(
          success: false,
          error: 'Failed to fetch location: ${response.statusCode}',
        );
      }
    } catch (e) {
      return LocationResult(
        success: false,
        error: 'Location service error: $e',
      );
    }
  }

  static Future<LocationResult> getLocationByCoords(double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse('http://api.openweathermap.org/geo/1.0/reverse?lat=$lat&lon=$lng&limit=1&appid=$apiKey'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        if (data.isNotEmpty) {
          final location = data[0];
          return LocationResult(
            success: true,
            latitude: lat,
            longitude: lng,
            address: "${location['name']}, ${location['state'] ?? ''}, ${location['country']}",
          );
        }
      }
      return LocationResult(
        success: true,
        latitude: lat,
        longitude: lng,
        address: "Location: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}",
      );
    } catch (e) {
      return LocationResult(
        success: false,
        error: 'Failed to get address: $e',
      );
    }
  }
}

class LocationService {
  static Future<LocationResult> getCurrentLocation() async {
    print('📍 LocationService: Starting location request...');
    
    try {
      // Step 1: Check if location service is enabled
      print('📍 Step 1: Checking location services...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('📍 Location services enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        print('❌ Location services disabled');
        return LocationResult(
          success: false,
          error: 'Location services are disabled. Please enable location on your device.',
          requiresPermissionRequest: false,
        );
      }

      // Step 2: Check and request permissions
      print('📍 Step 2: Checking permissions...');
      LocationPermission permission = await Geolocator.checkPermission();
      print('📍 Current permission: $permission');
      
      if (permission == LocationPermission.denied) {
        print('📍 Requesting location permission...');
        permission = await Geolocator.requestPermission();
        print('📍 Permission after request: $permission');
        
        if (permission == LocationPermission.denied) {
          print('❌ Location permission denied by user');
          return LocationResult(
            success: false,
            error: 'Location permissions are required to report issues.',
            requiresPermissionRequest: true,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permission permanently denied');
        return LocationResult(
          success: false,
          error: 'Location permissions are permanently denied. Please enable them in your device settings.',
          requiresPermissionRequest: false,
        );
      }

      // Step 3: Get current position with SINGLE ATTEMPT and reasonable timeout
      print('📍 Step 3: Getting current position...');
      Position position = await _getPositionWithTimeout();
      
      print('✅ Position obtained: ${position.latitude}, ${position.longitude}');

      // Step 4: Get address (don't wait too long)
      String address = "Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
      
      // Try to get better address in background
      _getAddressInBackground(position.latitude, position.longitude).then((addr) {
        if (addr != null) {
          print('📍 Background address update: $addr');
        }
      });

      print('✅ Location request completed successfully');
      return LocationResult(
        success: true,
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );

    } catch (e) {
      print('❌ Error in getCurrentLocation: $e');
      
      String errorMessage;
      if (e.toString().contains('Timeout') || e.toString().contains('timed out')) {
        errorMessage = 'Location request timed out. Please try again or use manual location.';
      } else if (e.toString().contains('PERMISSION_DENIED')) {
        errorMessage = 'Location permission denied. Please enable location permissions.';
      } else if (e.toString().contains('Location service disabled')) {
        errorMessage = 'Location services are disabled. Please enable location on your device.';
      } else {
        errorMessage = 'Unable to get location: ${e.toString()}';
      }
      
      return LocationResult(
        success: false,
        error: errorMessage,
        requiresPermissionRequest: false,
      );
    }
  }

  // FIXED: Single attempt with reasonable timeout instead of cascading timeouts
  static Future<Position> _getPositionWithTimeout() async {
    print('📍 Attempting to get position with 15 second timeout...');
    
    try {
      // Single attempt with medium accuracy - good balance of speed and accuracy
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 15), // Single reasonable timeout
      ).timeout(
        Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Location request timed out after 15 seconds');
        },
      );
    } catch (e) {
      print('❌ Position acquisition failed: $e');
      rethrow; // Let the parent handle the error
    }
  }

  // QUICK LOCATION METHOD - Alternative fast method
  static Future<LocationResult> getQuickLocation() async {
    try {
      print('📍 Getting quick location...');
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, // Faster but less accurate
        timeLimit: Duration(seconds: 10),
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          print('⏰ Quick location timed out, trying standard method...');
          throw TimeoutException('Quick location timeout');
        },
      );
      
      return LocationResult(
        success: true,
        latitude: position.latitude,
        longitude: position.longitude,
        address: "Quick location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}",
      );
    } catch (e) {
      print('📍 Quick location failed: $e');
      return getCurrentLocation(); // Fallback to standard method
    }
  }

  static Future<String?> _getAddressInBackground(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return "${place.street ?? ''} ${place.locality ?? ''} ${place.administrativeArea ?? ''}".trim();
      }
    } catch (e) {
      print('📍 Background address error: $e');
    }
    return null;
  }

  static Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  static Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}

class LocationResult {
  final bool success;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? error;
  final bool requiresPermissionRequest;

  LocationResult({
    required this.success,
    this.latitude,
    this.longitude,
    this.address,
    this.error,
    this.requiresPermissionRequest = false,
  });
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => message;
}