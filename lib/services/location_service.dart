import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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

      // Step 3: Get current position with lower accuracy for faster results
      print('📍 Step 3: Getting current position...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // Changed to medium for faster response
      ).timeout(const Duration(seconds: 10));
      
      print('✅ Position obtained: ${position.latitude}, ${position.longitude}');

      // Step 4: Get address (optional - don't let this block the main process)
      String address = "Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
      
      // Get address in background without waiting too long
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
        errorMessage = 'Location request timed out. Please check your connection and try again.';
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

  // Helper method to get address without blocking the main process
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

  // Check if we have location permission
  static Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  // Check if location services are enabled
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