// lib/pages/report_page.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class ReportPage extends StatefulWidget {
  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String? selectedLocation;
  double? currentLat;
  double? currentLong;
  String? currentAddress;
  bool isLoadingLocation = false;

  List<String> locationOptions = [
    'Select Location',
    'Use Current Location',
    'Enter Manually'
  ];

  Future<void> getCurrentLocation() async {
    setState(() {
      isLoadingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location services are disabled. Please enable them.')),
        );
        setState(() { isLoadingLocation = false; });
        return;
      }

      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location permissions are denied')),
          );
          setState(() { isLoadingLocation = false; });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permissions are permanently denied. Please enable them in app settings.')),
        );
        setState(() { isLoadingLocation = false; });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = "${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}";
        
        setState(() {
          currentLat = position.latitude;
          currentLong = position.longitude;
          currentAddress = address.isNotEmpty ? address : "Location: ${position.latitude}, ${position.longitude}";
          selectedLocation = currentAddress;
          isLoadingLocation = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location captured successfully!')),
        );
      }

    } catch (e) {
      setState(() {
        isLoadingLocation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  void onLocationSelected(String? value) {
    if (value == 'Use Current Location') {
      getCurrentLocation();
    } else {
      setState(() {
        selectedLocation = value;
      });
    }
  }

  void submitReport() {
    print('Submitting report with location:');
    print('Lat: $currentLat');
    print('Long: $currentLong');
    print('Address: $currentAddress');
    
    // Call your API here
    // Navigator.pop(context); // Go back after submission if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report Issue'),
        backgroundColor: Colors.blue, // Customize as needed
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Location Dropdown
            DropdownButtonFormField<String>(
              value: selectedLocation,
              items: locationOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: onLocationSelected,
              decoration: InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),

            SizedBox(height: 20),

            // Loading indicator
            if (isLoadingLocation)
              Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Getting your current location...'),
                ],
              ),

            // Show captured location
            if (currentLat != null && currentLong != null)
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📍 Location Captured', 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 12),
                      Text('Address: $currentAddress', style: TextStyle(fontSize: 14)),
                      SizedBox(height: 8),
                      Text('Latitude: $currentLat', style: TextStyle(fontSize: 14)),
                      Text('Longitude: $currentLong', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),

            Spacer(),

            // Submit Button
            ElevatedButton(
              onPressed: (currentLat != null && currentLong != null) ? submitReport : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: Text('Submit Report', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}