import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

class AdminMapViewPage extends StatefulWidget {
  const AdminMapViewPage({super.key});

  @override
  State<AdminMapViewPage> createState() => _AdminMapViewPageState();
}

class _AdminMapViewPageState extends State<AdminMapViewPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  final String apiKey = "e60aa95d14bf10cc8a3d5cfff82bb352";

  LatLng currentCenter = LatLng(18.5204, 73.8567); // Default: Pune
  double currentZoom = 10.0;
  List<Marker> issueMarkers = [];

  bool isLoading = true;
  bool isRefreshing = false;
  Map<String, dynamic>? selectedIssueInfo;

  @override
  void initState() {
    super.initState();
    _loadRealIssues();
  }

  Future<void> _loadRealIssues() async {
    setState(() => isLoading = true);

    try {
      final ApiService apiService = ApiService();
      final response = await apiService.getMapIssues();
      
      if (response.statusCode == 200) {
        final List<dynamic> issues = json.decode(response.body);
        _createMarkersFromRealData(issues);
      } else {
        throw Exception('Failed to load issues: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading issues: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load issues: $e')),
      );
      // Fallback to sample data
      _addSampleMarkers();
    }

    setState(() => isLoading = false);
  }

  // 🎯 Create markers from real backend data - SINGLE VERSION
  void _createMarkersFromRealData(List<dynamic> issues) {
    setState(() {
      issueMarkers.clear();
    });

    for (final issue in issues) {
      // Extract coordinates from your issue data structure
      final double? lat = _parseDouble(issue['location_lat'] ?? issue['latitude']);
      final double? lon = _parseDouble(issue['location_long'] ?? issue['longitude']);
      
      if (lat != null && lon != null) {
        final marker = _createIssueMarker(
          lat,
          lon,
          issue['status'] ?? 'Pending',
          issue['category'] ?? 'General Issue',
          issueId: issue['id'],
          title: issue['title'],
          description: issue['description'],
          createdAt: issue['created_at'],
          urgency: issue['urgency_level'],
          userEmail: issue['user_email'],
        );
        setState(() {
          issueMarkers.add(marker);
        });
      }
    }
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // 🗺️ Create marker with real issue data
  Marker _createIssueMarker(
    double lat, 
    double lon, 
    String status, 
    String type, {
    int? issueId,
    String? title,
    String? description,
    String? createdAt,
    String? urgency,
    String? userEmail,
  }) {
    Color markerColor = _getStatusColor(status);

    return Marker(
      width: 28,
      height: 28,
      point: LatLng(lat, lon),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedIssueInfo = {
              'id': issueId,
              'lat': lat,
              'lon': lon,
              'status': status,
              'type': type,
              'title': title,
              'description': description,
              'created_at': createdAt,
              'urgency': urgency,
              'user_email': userEmail,
            };
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: markerColor.withOpacity(0.9),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              _getStatusIcon(status),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return '!';
      case 'in progress':
        return '⟳';
      case 'resolved':
        return '✓';
      default:
        return '•';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.red;
      case 'in progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  // 🔄 Refresh data
  Future<void> _refreshData() async {
    setState(() => isRefreshing = true);
    await _loadRealIssues();
    setState(() => isRefreshing = false);
  }

  // 🔍 Search location
  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    setState(() => isLoading = true);

    try {
      final geoUrl =
          'https://api.openweathermap.org/geo/1.0/direct?q=$query&limit=1&appid=$apiKey';
      final response = await http.get(Uri.parse(geoUrl));
      final data = json.decode(response.body);

      if (data.isNotEmpty) {
        final lat = data[0]['lat'];
        final lon = data[0]['lon'];

        setState(() {
          currentCenter = LatLng(lat, lon);
          currentZoom = 15.0;
        });

        _mapController.move(currentCenter, currentZoom);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Location not found")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  // Fallback sample data
  void _addSampleMarkers() {
    final sampleIssues = [
      {
        'location_lat': 18.5204,
        'location_long': 73.8567,
        'status': 'Pending',
        'category': 'Garbage',
        'id': 1,
        'title': 'Sample Issue 1',
        'description': 'This is a sample issue',
        'urgency_level': 'High'
      },
      {
        'location_lat': 18.5304,
        'location_long': 73.8667,
        'status': 'In Progress',
        'category': 'Water',
        'id': 2,
        'title': 'Sample Issue 2',
        'description': 'This is another sample issue',
        'urgency_level': 'Medium'
      },
    ];
    
    _createMarkersFromRealData(sampleIssues);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white, size: 24),
          onPressed: _refreshData,
        ),
        title: const Text(
          'Admin Map View',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1a237e),
        elevation: 10,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        actions: [
          if (isRefreshing)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentCenter,
              initialZoom: currentZoom,
              minZoom: 2,
              maxZoom: 18,
              onTap: (tapPosition, point) {
                setState(() {
                  selectedIssueInfo = null;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.civiceye',
              ),
              MarkerLayer(markers: issueMarkers),
            ],
          ),

          // 🔍 Search Bar
          Positioned(
            top: 10,
            left: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: "Search location...",
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) => _searchLocation(value),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.blueAccent),
                    onPressed: () => _searchLocation(_searchController.text.trim()),
                  ),
                ],
              ),
            ),
          ),

          // 🎯 Status Legend
          Positioned(
            bottom: 20,
            left: 15,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Issue Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildLegendItem(Colors.red, 'Pending', '!'),
                  _buildLegendItem(Colors.orange, 'In Progress', '⟳'),
                  _buildLegendItem(Colors.green, 'Resolved', '✓'),
                ],
              ),
            ),
          ),

          // 🗂 Issue Info Box
          if (selectedIssueInfo != null)
            Positioned(
              top: 80,
              left: 20,
              right: 20,
              child: _buildIssueInfoBox(),
            ),

          if (isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "refresh",
            mini: true,
            backgroundColor: Colors.blueAccent,
            onPressed: _refreshData,
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "zoomIn",
            mini: true,
            backgroundColor: Colors.blueAccent,
            onPressed: _zoomIn,
            child: const Icon(Icons.zoom_in),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "zoomOut",
            mini: true,
            backgroundColor: Colors.blueAccent,
            onPressed: _zoomOut,
            child: const Icon(Icons.zoom_out),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueInfoBox() {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Issue #${selectedIssueInfo!['id'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() {
                      selectedIssueInfo = null;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // Title
            if (selectedIssueInfo!['title'] != null)
              Text(
                selectedIssueInfo!['title'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            
            const SizedBox(height: 8),
            
            // Status
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getStatusColor(selectedIssueInfo!['status']),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Status: ${selectedIssueInfo!['status']}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 6),
            
            // Type
            Text(
              'Type: ${selectedIssueInfo!['type']}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            
            // Urgency
            if (selectedIssueInfo!['urgency'] != null)
              Text(
                'Urgency: ${selectedIssueInfo!['urgency']}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            
            // User Email
            if (selectedIssueInfo!['user_email'] != null)
              Text(
                'Reported by: ${selectedIssueInfo!['user_email']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            
            // Created Date
            if (selectedIssueInfo!['created_at'] != null)
              Text(
                'Reported: ${_formatDate(selectedIssueInfo!['created_at'])}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildLegendItem(Color color, String text, String icon) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: Center(
            child: Text(
              icon,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  void _zoomIn() {
    setState(() {
      currentZoom = (currentZoom + 1).clamp(2.0, 18.0);
    });
    _mapController.move(currentCenter, currentZoom);
  }

  void _zoomOut() {
    setState(() {
      currentZoom = (currentZoom - 1).clamp(2.0, 18.0);
    });
    _mapController.move(currentCenter, currentZoom);
  }
}