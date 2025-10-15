import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
// import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static Future<LocationResult> getCurrentLocation() async {
    try {
      
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult(
          success: false,
          error: 'Location services are disabled. Please enable them.',
          requiresPermissionRequest: false,
        );
      }

      
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult(
            success: false,
            error: 'Location permissions are denied',
            requiresPermissionRequest: true,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult(
          success: false,
          error: 'Location permissions are permanently denied, we cannot request permissions.',
          requiresPermissionRequest: false,
        );
      }

      
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          )
        );

        
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        String address = "Coordinates: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}";
        
        if (placemarks.isNotEmpty && placemarks[0].street != null) {
          Placemark place = placemarks[0];
          address = "${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}";
          address = address.replaceAll(RegExp(r', ,'), ',').replaceAll(RegExp(r'^,\s*'), '');
        }

        return LocationResult(
          success: true,
          latitude: position.latitude,
          longitude: position.longitude,
          address: address,
        );
      } else {
        return LocationResult(
          success: false,
          error: 'Location permission not granted',
          requiresPermissionRequest: false,
        );
      }

    } catch (e) {
      return LocationResult(
        success: false,
        error: 'Failed to get location: $e',
        requiresPermissionRequest: false,
      );
    }
  }

  
  static Future<void> openAppSettings() async {
    await openAppSettings();
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