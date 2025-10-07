import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '/services/issue_service.dart'; 
import 'dart:async'; 

const _indigo = Colors.indigo;
const _green = Colors.green;


class ReportIssuePage extends StatefulWidget {
  final String category;

  const ReportIssuePage({super.key, required this.category});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _otherIssue = TextEditingController();
  final _manualLocation = TextEditingController();
  final _textDescription = TextEditingController();

  // State
  String? _issueType;
  String? _locationChoice;
  String? _urgency;
  bool _hasAttachmentPhoto = false;
  bool _hasAttachmentVideo = false;
  bool _hasAttachmentVoice = false;
  bool _showOtherIssue = false;
  final bool _showManualLocation = false;
  bool _showTextDescription = false;
  
  // Location variables
  double? _currentLat;
  double? _currentLong;
  String? _currentAddress;
  bool _isLoadingLocation = false;

  // color tokens (used selectively)
  static const Color _indigo = Color(0xFF3F51B5); // main indigo
  static const Color _indigoLight = Color(0xFF6F7BE6);

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _otherIssue.dispose();
    _manualLocation.dispose();
    _textDescription.dispose();
    super.dispose();
  }

  // ====== simple validations ====
  bool _validateRequired() {
    return _name.text.isNotEmpty &&
        _phone.text.isNotEmpty &&
        _issueType != null &&
        _textDescription.text.isNotEmpty; 
  }

  // ====== LOCATION FUNCTIONALITY ======
  Future<void> _getCurrentLocation() async {
  setState(() {
    _isLoadingLocation = true;
  });

  try {
    // ✅ STEP 1: Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Show dialog to enable location services
      bool? enableService = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text('Please enable location services to use this feature.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Enable'),
            ),
          ],
        ),
      );
      
      if (enableService == true) {
        await Geolocator.openLocationSettings();
      }
      
      setState(() { _isLoadingLocation = false; });
      return;
    }

    // ✅ STEP 2: Check and request permissions with proper user prompts
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      // Show permission request dialog first
      bool? requestPermission = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text('This app needs location access to capture your current location for issue reporting.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Deny'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Allow'),
            ),
          ],
        ),
      );
      
      if (requestPermission != true) {
        setState(() { _isLoadingLocation = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required to use this feature.')),
        );
        return;
      }
      
      // Now request the actual permission
      permission = await Geolocator.requestPermission();
      
      if (permission == LocationPermission.denied) {
        setState(() { _isLoadingLocation = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied. Please enable in app settings.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() { _isLoadingLocation = false; });
      
      // Show dialog to guide user to app settings
      bool? openSettings = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text('Location permissions are permanently denied. Please enable them in app settings.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      
      if (openSettings == true) {
        await Geolocator.openAppSettings();
      }
      return;
    }

    // ✅ STEP 3: Only now get the current position
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15), // Add timeout
      ).timeout(const Duration(seconds: 20), onTimeout: () {
        throw TimeoutException('Location request timed out');
      });

      // ✅ STEP 4: Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        return [Placemark()]; // Return empty placemark if timeout
      });

      String address = "Coordinates: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}";
      
      if (placemarks.isNotEmpty && placemarks[0].street != null) {
        Placemark place = placemarks[0];
        address = "${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}";
        address = address.replaceAll(RegExp(r', ,'), ',').replaceAll(RegExp(r'^,\s*'), '');
      }
      
      setState(() {
        _currentLat = position.latitude;
        _currentLong = position.longitude;
        _currentAddress = address.isNotEmpty ? address : "Location: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}";
        _locationChoice = _currentAddress;
        _isLoadingLocation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📍 Location captured successfully!')),
      );
    }

  } on TimeoutException catch (e) {
    setState(() {
      _isLoadingLocation = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Location request timed out: ${e.message}')),
    );
  } catch (e) {
    setState(() {
      _isLoadingLocation = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error getting location: $e')),
    );
  }
}

  // ====== Handlers (stubs) ======
  void _showChoiceSheet(String title, List<String> items, Function(String) onPick) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => _ChoiceSheet(title: title, items: items),
    );
    if (choice != null) onPick(choice);
  }

  void _showIssueTypeMenu() {
    _showChoiceSheet('Choose Issue Type', [
      '🛣️ Pothole',
      '🗑️ Garbage',
      '💧 Water Leak',
      '💡 Streetlight Issue',
      '🐕 Stray Animals',
      '🚧 Other',
    ], (c) {
      setState(() {
        _issueType = c;
        _showOtherIssue = c.contains('Other');
      });
    });
  }

    void _showLocationMenu() {
    _showChoiceSheet('Location', [
      '📍 Current location',
      '🗺️ Locate on map',
    ], (c) async {
      if (c.contains('Current')) {
        // ✅ FIXED: Ask for permissions first before capturing
        await _getCurrentLocation();
      } else if (c.contains('map')) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MapPickPage()));
      }
    });
  }

  void _showUploadMenu() {
    _showChoiceSheet('Upload', [
      '📸 Photo/Video (Camera)',
      '🖼️ Photo/Video (Gallery)',
      '🎤 Voice Note',
    ], (c) {
      setState(() {
        if (c.contains('Camera')) _hasAttachmentPhoto = true;
        if (c.contains('Gallery')) _hasAttachmentVideo = true;
        if (c.contains('Voice')) _hasAttachmentVoice = true;
        if (c.contains('Text')) _showTextDescription = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected: $c')));
    });
  }

  void _handleSubmit() async {
    if (!_validateRequired()) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please fill required fields.')));
      return;
    }

    // Check if location is captured when current location is selected
    if (_locationChoice != null && _locationChoice!.contains('Current') && _currentLat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for location to be captured or select another location option.')),
      );
      return;
    }

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Prepare location data for backend
      String locationData;
      if (_currentLat != null && _currentLong != null) {
        locationData = '${_currentAddress ?? "Current Location"} (${_currentLat!.toStringAsFixed(6)}, ${_currentLong!.toStringAsFixed(6)})';
      } else {
        locationData = _manualLocation.text.isEmpty ? 'Location not specified' : _manualLocation.text;
      }

      // Send to backend
      final response = await IssueService.reportIssue(
        title: _textDescription.text.split(' ').take(5).join(' '), // Short title
        description: _textDescription.text,
        category: _issueType ?? 'General',
        location: locationData, // ✅ UPDATED: Includes coordinates if available
        reporterName: _name.text,
        reporterPhone: _phone.text,
        reporterEmail: _email.text.isEmpty ? null : _email.text,
        urgency: _urgency ?? 'Medium',
      );

      // Hide loading
      Navigator.pop(context);

      // Navigate to confirmation
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ConfirmationPage(payload: response),
        ),
      );
      
    } catch (e) {
      // Hide loading if still showing
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit issue: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            pinned: true,
            automaticallyImplyLeading: false,
            expandedHeight: 220,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: _CurvedHeader(
                gradientColors: [Colors.teal.shade800, Colors.teal.shade400],
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Stack(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _HoverCircleButton(
                              icon: Icons.arrow_back_ios_new,
                              semanticLabel: 'Back',
                              onTap: () => Navigator.of(context).maybePop(),
                            ),
                            const SizedBox(width: 12),
                            _HoverCircleButton(
                              icon: Icons.help_outline_rounded,
                              semanticLabel: 'Help',
                              onTap: () => showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('How to report'),
                                  content: RichText(
                                    text: const TextSpan(
                                      style: TextStyle(color: Colors.black87),
                                      children: [
                                        TextSpan(text: '• ', style: TextStyle(fontWeight: FontWeight.bold)),
                                        TextSpan(text: 'Add photo, video or voice note.\n\n'),
                                        TextSpan(text: '• ', style: TextStyle(fontWeight: FontWeight.bold)),
                                        TextSpan(text: 'Confirm your location (GPS, map, or manual entry).\n\n'),
                                        TextSpan(text: '• ', style: TextStyle(fontWeight: FontWeight.bold)),
                                        TextSpan(text: 'Choose the issue type and type a short description.\n\n'),
                                        TextSpan(text: '• ', style: TextStyle(fontWeight: FontWeight.bold)),
                                        TextSpan(text: 'Review the information and submit the report.'),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK')
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: _HoverCircleButton(
                            icon: Icons.account_circle_rounded,
                            semanticLabel: 'Profile',
                            onTap: () => ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(content: Text('Profile'))),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Want to report issue?',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  )),
                              const SizedBox(height: 6),
                              Text('Help us make the city better',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withOpacity(0.95),
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Contact fields
              _FieldCard(
                label: 'Name *',
                child: TextField(
                  controller: _name,
                  decoration: const InputDecoration(hintText: 'Enter your full name', border: InputBorder.none),
                  textInputAction: TextInputAction.next,
                ),
              ),
              _FieldCard(
                label: 'Phone *',
                child: TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(hintText: 'Enter phone number', border: InputBorder.none),
                  textInputAction: TextInputAction.next,
                ),
              ),
              _FieldCard(
                label: 'Email (optional)',
                child: TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'Enter email', border: InputBorder.none),
                  textInputAction: TextInputAction.next,
                ),
              ),

              // Issue type
              _FieldCard(
                label: 'Report issue *',
                child: _MenuTile(valueText: _issueType ?? 'Choose…', onTap: _showIssueTypeMenu),
              ),
              if (_showOtherIssue)
                _FieldCard(
                  label: 'Describe "Other"',
                  child: TextField(
                    controller: _otherIssue,
                    decoration: const InputDecoration(hintText: 'Type the issue…', border: InputBorder.none),
                    maxLines: 2,
                  ),
                ),
              // Description (compulsory)
              _FieldCard(
                label: 'Description *',
                child: TextField(
                  controller: _textDescription,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Describe the issue in detail…',
                    border: InputBorder.none,
                  ),
                  textInputAction: TextInputAction.newline,
                ),
              ),

              // Location
              _FieldCard(
                label: 'Location',
                child: _MenuTile(valueText: _locationChoice ?? 'Select location option…', onTap: _showLocationMenu),
              ),
              
              // ✅ NEW: Show loading when getting location
              if (_isLoadingLocation)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const CircularProgressIndicator(strokeWidth: 2),
                      const SizedBox(width: 12),
                      Text('Getting your current location...', 
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.blue.shade800)),
                    ],
                  ),
                ),

              // ✅ NEW: Show captured location details
              if (_currentLat != null && _currentLong != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.green.shade700, size: 18),
                          const SizedBox(width: 8),
                          Text('📍 Location Captured', 
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              )),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Address: $_currentAddress', 
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.green.shade700)),
                      const SizedBox(height: 4),
                      Text('Coordinates: ${_currentLat!.toStringAsFixed(6)}, ${_currentLong!.toStringAsFixed(6)}', 
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.green.shade700)),
                    ],
                  ),
                ),

              if (_showManualLocation)
                _FieldCard(
                  label: 'Enter location manually',
                  child: TextField(
                    controller: _manualLocation,
                    decoration: const InputDecoration(hintText: 'House no., street, landmark…', border: InputBorder.none),
                    maxLines: 2,
                  ),
                ),

              // Upload
              _FieldCard(
                label: 'Upload',
                child: _MenuTile(valueText: 'Choose attachment…', onTap: _showUploadMenu),
              ),

              // Badges row (attachments)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_hasAttachmentPhoto) _Badge(text: 'Photo attached', icon: Icons.photo),
                    if (_hasAttachmentVideo) _Badge(text: 'Video attached', icon: Icons.videocam),
                    if (_hasAttachmentVoice) _Badge(text: 'Voice note attached', icon: Icons.mic),
                  ],
                ),
              ),

              // Text description
              if (_showTextDescription)
                _FieldCard(
                  label: 'Text Description',
                  child: TextField(
                    controller: _textDescription,
                    maxLines: 4,
                    decoration: const InputDecoration(hintText: 'Describe the issue…', border: InputBorder.none),
                  ),
                ),
              // CTA row: Submit + Quick action (preview)
              Row(
                children: [
                  Expanded(
                    child: _SubmitButton(
                      gradient: [_indigo, _indigoLight],
                      onPressed: _handleSubmit,
                      label: 'Submit',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // small hint
              Text(
                '* Required fields',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ================= Confirmation Page =================
class ConfirmationPage extends StatelessWidget {
  final Map payload;
  const ConfirmationPage({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String urgency = payload['urgency']?.toString() ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(title: const Text('Submitted')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Text('Issue Submitted', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 12),
                _kv('Type', payload['issueType'] ?? '—'),
                _kv('Urgency', urgency),
                if (payload['location'] != null) _kv('Location', payload['location']),
                if (payload['description'] != null) _kv('Description', payload['description']),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    if (payload['hasPhoto'] == true) _Badge(text: 'Photo attached', icon: Icons.photo),
                    if (payload['hasVideo'] == true) _Badge(text: 'Video attached', icon: Icons.videocam),
                    if (payload['hasVoice'] == true) _Badge(text: 'Voice note', icon: Icons.mic),
                  ],
                ),
              ]),
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            icon: const Icon(Icons.location_searching),
            label: const Text('Track your issue'),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TrackIssuePage()));
            },
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text('Done'),
          ),
        ]),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 92, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))),
        const SizedBox(width: 8),
        Expanded(child: Text(v)),
      ]),
    );
  }
}

/// ================ Track Page Stub =================
class TrackIssuePage extends StatelessWidget {
  const TrackIssuePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track Issue')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _TimelineTile(state: 'Submitted', time: 'Just now', isDone: true),
          _TimelineTile(state: 'Assigned to dept.', time: '—', isDone: false),
          _TimelineTile(state: 'In progress', time: '—', isDone: false),
          _TimelineTile(state: 'Resolved', time: '—', isDone: false),
        ],
      ),
    );
  }
}

/// ===================== Reusable UI pieces =====================

class _CurvedHeader extends StatelessWidget {
  final List<Color> gradientColors;
  final Widget child;
  const _CurvedHeader({required this.gradientColors, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CurvePainter(gradientColors), child: child);
  }
}

class _CurvePainter extends CustomPainter {
  final List<Color> colors;
  _CurvePainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    ).createShader(rect);

    final paint = Paint()..shader = shader;

    // Draw a rectangle with rounded bottom corners
    final rrect = RRect.fromRectAndCorners(
      rect,
      topLeft: const Radius.circular(24),
      topRight: const Radius.circular(24),
      bottomLeft: const Radius.circular(48),
      bottomRight: const Radius.circular(48),
    );

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _CurvePainter oldDelegate) => oldDelegate.colors != colors;
}

/// Small hover-able circular icon button (works on web & mobile)
class _HoverCircleButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? semanticLabel;
  const _HoverCircleButton({required this.icon, required this.onTap, this.semanticLabel});
  @override
  State<_HoverCircleButton> createState() => _HoverCircleButtonState();
}

class _HoverCircleButtonState extends State<_HoverCircleButton> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(_hover ? 0.26 : 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(_hover ? 0.7 : 0.45)),
            boxShadow: _hover ? [const BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))] : null,
          ),
          child: Icon(widget.icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final String label;
  final Widget child;
  const _FieldCard({required this.label, required this.child});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [const BoxShadow(color: Colors.black, blurRadius: 12, offset: Offset(0, 6))],
        border: Border.all(color: Colors.black12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: theme.textTheme.labelLarge?.copyWith(color: _indigo.withOpacity(0.95), fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        child,
      ]),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final String valueText;
  final VoidCallback onTap;
  const _MenuTile({required this.valueText, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(valueText),
      trailing: const Icon(Icons.expand_more_rounded),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ChoiceSheet extends StatelessWidget {
  final String title;
  final List<String> items;
  const _ChoiceSheet({required this.title, required this.items});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Wrap(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child:
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ),
        for (final item in items)
          _HoverListTile(
            title: item,
            onTap: () => Navigator.pop(context, item),
          ),
        const SizedBox(height: 8),
      ]),
    );
  }
}

class _HoverListTile extends StatefulWidget {
  final String title;
  final VoidCallback onTap;

  const _HoverListTile({
    required this.title,
    required this.onTap,
  });

  @override
  State<_HoverListTile> createState() => _HoverListTileState();
}

class _HoverListTileState extends State<_HoverListTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Material(
        color: _hovering ? const Color(0xFFE3F2FD) : Colors.transparent,
        child: ListTile(
          title: Text(widget.title),
          onTap: widget.onTap,
          dense: true,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final IconData icon;
  const _Badge({required this.text, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _indigo.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _indigo.withOpacity(0.28)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: _indigo),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _indigo)),
      ]),
    );
  }
}

class _SubmitButton extends StatefulWidget {
  final List<Color> gradient;
  final VoidCallback onPressed;
  final String label;
  const _SubmitButton({required this.gradient, required this.onPressed, this.label = 'Submit'});
  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: widget.gradient),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _hover ? [const BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6))] : null,
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          onPressed: widget.onPressed,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.send, size: 18, color: Colors.white.withOpacity(0.98)),
            const SizedBox(width: 8),
            Text(widget.label),
          ]),
        ),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final String state;
  final String time;
  final bool isDone;
  const _TimelineTile({required this.state, required this.time, required this.isDone});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading:
          Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, color: isDone ? _green : Colors.black26),
      title: Text(state),
      subtitle: Text(time),
    );
  }
}

// Map pick stub
class MapPickPage extends StatelessWidget {
  const MapPickPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick on Map')),
      body: Center(
        child: OutlinedButton.icon(
          icon: const Icon(Icons.check),
          label: const Text('Pretend we picked a location'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
}