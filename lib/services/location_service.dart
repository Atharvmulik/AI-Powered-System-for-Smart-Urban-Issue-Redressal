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
  /// Main method to get current location with multiple fallback strategies
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

      // Step 3: Try multiple strategies to get location
      print('📍 Step 3: Attempting to get position...');
      
      // Strategy 1: Try last known location first (instant)
      Position? position = await _getLastKnownLocation();
      
      if (position == null) {
        // Strategy 2: Try quick low-accuracy location (5 seconds)
        print('📍 No cached location, trying quick GPS...');
        position = await _getQuickPosition();
      }
      
      if (position == null) {
        // Strategy 3: Final attempt with medium accuracy (10 seconds)
        print('📍 Quick GPS failed, trying standard GPS...');
        position = await _getStandardPosition();
      }
      
      if (position == null) {
        throw Exception('Unable to get location after all attempts');
      }
      
      print('✅ Position obtained: ${position.latitude}, ${position.longitude}');
      print('📍 Accuracy: ${position.accuracy}m');

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
        errorMessage = 'Location request timed out. Please ensure GPS is enabled and you are in an open area. Try "Search City" or "Enter Manually" instead.';
      } else if (e.toString().contains('PERMISSION_DENIED')) {
        errorMessage = 'Location permission denied. Please enable location permissions.';
      } else if (e.toString().contains('Location service disabled')) {
        errorMessage = 'Location services are disabled. Please enable location on your device.';
      } else {
        errorMessage = 'Unable to get location. Please try "Search City" or "Enter Manually".';
      }
      
      return LocationResult(
        success: false,
        error: errorMessage,
        requiresPermissionRequest: false,
      );
    }
  }

  /// Strategy 1: Get last known location (instant, but might be stale)
  static Future<Position?> _getLastKnownLocation() async {
    try {
      print('📍 Attempting to get last known location...');
      Position? lastPosition = await Geolocator.getLastKnownPosition();
      
      if (lastPosition != null) {
        // Check if last position is recent (within 5 minutes)
        final age = DateTime.now().difference(lastPosition.timestamp);
        print('📍 Last known location age: ${age.inMinutes} minutes');
        
        if (age.inMinutes < 5) {
          print('✅ Using recent cached location');
          return lastPosition;
        } else {
          print('⚠️ Cached location too old, will try fresh GPS');
        }
      }
    } catch (e) {
      print('⚠️ No last known location: $e');
    }
    return null;
  }

  /// Strategy 2: Quick low-accuracy position (5 seconds timeout)
  static Future<Position?> _getQuickPosition() async {
    try {
      print('📍 Attempting quick low-accuracy position (5s timeout)...');
      
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 5),
      ).timeout(
        Duration(seconds: 5),
        onTimeout: () {
          print('⏰ Quick position timed out');
          throw TimeoutException('Quick position timed out');
        },
      );
    } catch (e) {
      print('⚠️ Quick position failed: $e');
      return null;
    }
  }

  /// Strategy 3: Standard medium-accuracy position (10 seconds timeout)
  static Future<Position?> _getStandardPosition() async {
    try {
      print('📍 Attempting standard position (10s timeout)...');
      
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          print('⏰ Standard position timed out');
          throw TimeoutException('Standard position timed out');
        },
      );
    } catch (e) {
      print('⚠️ Standard position failed: $e');
      return null;
    }
  }

  /// KEPT FOR BACKWARD COMPATIBILITY - Alias for getCurrentLocation
  static Future<LocationResult> getQuickLocation() async {
    print('📍 getQuickLocation called - using getCurrentLocation...');
    return getCurrentLocation();
  }

  /// Get address from coordinates in background (non-blocking)
  static Future<String?> _getAddressInBackground(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng)
          .timeout(Duration(seconds: 5));
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
        
        return address.isNotEmpty ? address : null;
      }
    } catch (e) {
      print('📍 Background address error: $e');
    }
    return null;
  }

  /// Validate manual coordinates input
  /// Format: "latitude, longitude" or "lat,lng"
  /// Example: "21.1458, 79.0882" or "21.1458,79.0882"
  static LocationResult? parseManualCoordinates(String input) {
    try {
      // Remove extra spaces and split by comma
      String cleaned = input.trim().replaceAll(' ', '');
      List<String> parts = cleaned.split(',');
      
      if (parts.length != 2) {
        return LocationResult(
          success: false,
          error: 'Invalid format. Use: latitude, longitude\nExample: 21.1458, 79.0882',
        );
      }
      
      double lat = double.parse(parts[0]);
      double lng = double.parse(parts[1]);
      
      // Validate latitude range (-90 to 90)
      if (lat < -90 || lat > 90) {
        return LocationResult(
          success: false,
          error: 'Latitude must be between -90 and 90',
        );
      }
      
      // Validate longitude range (-180 to 180)
      if (lng < -180 || lng > 180) {
        return LocationResult(
          success: false,
          error: 'Longitude must be between -180 and 180',
        );
      }
      
      return LocationResult(
        success: true,
        latitude: lat,
        longitude: lng,
        address: 'Manual Location: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
      );
      
    } catch (e) {
      return LocationResult(
        success: false,
        error: 'Invalid coordinates. Use format: latitude, longitude\nExample: 21.1458, 79.0882',
      );
    }
  }

  // Utility methods
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