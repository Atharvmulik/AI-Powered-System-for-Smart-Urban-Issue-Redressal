import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static Future<LocationResult> getCurrentLocation() async {
    print('📍 LocationService: Starting location request...');
    
    try {
      // Check if location service is enabled
      print('📍 Checking if location services are enabled...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('📍 Location services enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        print('📍 Location services are disabled');
        return LocationResult(
          success: false,
          error: 'Location services are disabled. Please enable them.',
          requiresPermissionRequest: false,
        );
      }

      // Check permissions
      print('📍 Checking location permissions...');
      LocationPermission permission = await Geolocator.checkPermission();
      print('📍 Current permission: $permission');
      
      if (permission == LocationPermission.denied) {
        print('📍 Requesting location permission...');
        permission = await Geolocator.requestPermission();
        print('📍 Permission after request: $permission');
        
        if (permission == LocationPermission.denied) {
          print('📍 Location permission denied');
          return LocationResult(
            success: false,
            error: 'Location permissions are denied',
            requiresPermissionRequest: true,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('📍 Location permission permanently denied');
        return LocationResult(
          success: false,
          error: 'Location permissions are permanently denied. Please enable them in app settings.',
          requiresPermissionRequest: false,
        );
      }

      // Get current position
      print('📍 Getting current position...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15), // Add timeout
      );
      
      print('📍 Position obtained: ${position.latitude}, ${position.longitude}');

      // Get address from coordinates
      String address = "Coordinates: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}";
      
      try {
        print('📍 Getting address from coordinates...');
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          address = "${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}";
          address = address.replaceAll(RegExp(r', ,'), ',').replaceAll(RegExp(r'^,\s*'), '');
          print('📍 Address obtained: $address');
        }
      } catch (e) {
        print('📍 Error getting address: $e');
        // Continue with coordinates-only address
      }

      print('📍 Location request completed successfully');
      return LocationResult(
        success: true,
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );

    } catch (e) {
      print('📍 Error in getCurrentLocation: $e');
      return LocationResult(
        success: false,
        error: 'Failed to get location: $e',
        requiresPermissionRequest: false,
      );
    }
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