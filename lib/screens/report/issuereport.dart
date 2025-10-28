import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '/services/issue_service.dart'; 
import '/services/location_service.dart'; 
import 'dart:async'; 
import 'dart:io';


const _indigo = Colors.indigo;
const _green = Colors.green;
const _red = Colors.red;
const _orange = Colors.orange;

class ReportIssuePage extends StatefulWidget {
  const ReportIssuePage({super.key});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _manualLocation = TextEditingController();
  final _textDescription = TextEditingController();

  // State
  String? _urgencyLevel;
  String? _locationChoice;
  bool _showManualLocation = false;
  
  // Location variables
  double? _currentLat;
  double? _currentLong;
  String? _currentAddress;
  bool _isLoadingLocation = false;

  // Image variables
  File? _selectedImage;
  bool _isUploadingImage = false;

  // Service instance
  final IssueService _issueService = IssueService();
  final ImagePicker _imagePicker = ImagePicker();

  // color tokens
  static const Color _indigo = Color(0xFF3F51B5);
  static const Color _indigoLight = Color(0xFF6F7BE6);

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _manualLocation.dispose();
    _textDescription.dispose();
    super.dispose();
  }
  // ====== simple validations ====
  bool _validateRequired() {
    return _name.text.isNotEmpty &&
        _phone.text.isNotEmpty &&
        _urgencyLevel != null &&
        _locationChoice != null &&
        _textDescription.text.isNotEmpty;
  }

  // ====== LOCATION FUNCTIONALITY ======
Future<void> _getCurrentLocation() async {
  if (!mounted) return;
  
  setState(() {
    _isLoadingLocation = true;
  });

  try {
    print('🔄 Starting location request...');
    
    // Add timeout to prevent freezing
    LocationResult result = await LocationService.getCurrentLocation()
        .timeout(Duration(seconds: 30), onTimeout: () {
      print('⏰ Location request timed out');
      return LocationResult(
        success: false,
        error: 'Location request timed out. Please try again.',
        requiresPermissionRequest: false,
      );
    });

    if (!mounted) return;

    if (result.success) {
      print('✅ Location captured successfully');
      setState(() {
        _currentLat = result.latitude;
        _currentLong = result.longitude;
        _currentAddress = result.address ?? "Location: ${result.latitude!.toStringAsFixed(6)}, ${result.longitude!.toStringAsFixed(6)}";
        _locationChoice = '📍 Current location';
        _isLoadingLocation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📍 Location captured successfully!')),
      );
    } else {
      print('❌ Location failed: ${result.error}');
      setState(() {
        _isLoadingLocation = false;
      });

      if (result.requiresPermissionRequest) {
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
        
        if (requestPermission == true) {
          await _getCurrentLocation();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: ${result.error}')),
        );
      }
    }

  } catch (e) {
    print('💥 Error in _getCurrentLocation: $e');
    if (mounted) {
      setState(() {
        _isLoadingLocation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }
}

  // ====== IMAGE UPLOAD FUNCTIONALITY ======
  Future<void> _showImageSourceDialog() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      await _pickImage(source);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _isUploadingImage = true;
        });

        // Simulate image processing
        await Future.delayed(const Duration(seconds: 1));
        
        setState(() {
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📷 Image added successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  // ====== HANDLERS ======
  void _showChoiceSheet(String title, List<String> items, Function(String) onPick) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => _ChoiceSheet(title: title, items: items),
    );
    if (choice != null) onPick(choice);
  }

  void _showUrgencyMenu() {
    _showChoiceSheet('Select Urgency Level', [
      '🔴 High - Immediate attention required',
      '🟡 Medium - Address within 24 hours',
      '🟢 Low - Can be addressed later',
    ], (c) {
      setState(() {
        if (c.contains('High')) _urgencyLevel = 'High';
        else if (c.contains('Medium')) _urgencyLevel = 'Medium';
        else if (c.contains('Low')) _urgencyLevel = 'Low';
      });
    });
  }

  void _showLocationMenu() {
    _showChoiceSheet('Location', [
      '📍 Current location',
      '✏️ Enter manually',
    ], (c) async {
      if (c.contains('Current')) {
        await _getCurrentLocation();
      } else if (c.contains('manually')) {
        setState(() {
          _locationChoice = '✏️ Manual location';
          _showManualLocation = true;
        });
      }
    });
  }

  void _handleSubmit() async {
    if (!_validateRequired()) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please fill all required fields.')));
      return;
    }

    if (_locationChoice != null && _locationChoice!.contains('Current') && _currentLat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for location to be captured or select another location option.')),
      );
      return;
    }

    if (_locationChoice != null && _locationChoice!.contains('Manual') && _manualLocation.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter manual location details.')),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      String locationAddress;
      double latitude;
      double longitude;
      
      if (_currentLat != null && _currentLong != null) {
        locationAddress = _currentAddress ?? "Current Location (${_currentLat!.toStringAsFixed(6)}, ${_currentLong!.toStringAsFixed(6)})";
        latitude = _currentLat!;
        longitude = _currentLong!;
      } else if (_manualLocation.text.isNotEmpty) {
        locationAddress = _manualLocation.text;
        latitude = 0.0;
        longitude = 0.0;
      } else {
        locationAddress = 'Location not specified';
        latitude = 0.0;
        longitude = 0.0;
      }

      // Prepare report data
      Map<String, dynamic> reportData = {
        'user_name': _name.text,
        'user_mobile': _phone.text,
        'user_email': _email.text.isEmpty ? null : _email.text,
        'urgency_level': _urgencyLevel,
        'title': _textDescription.text.split(' ').take(5).join(' '),
        'description': _textDescription.text,
        'location_lat': latitude,
        'location_long': longitude,
        'location_address': locationAddress,
      };

      final response = await _issueService.submitReport(reportData);

      if (mounted) Navigator.pop(context);

      if (response['success']) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ConfirmationPage(payload: {
                'urgency': _urgencyLevel,
                'location': locationAddress,
                'description': _textDescription.text,
                'hasImage': _selectedImage != null,
              }),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit issue: ${response['error']}')),
          );
        }
      }
      
    } catch (e) {
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit issue: $e')),
        );
      }
    }
  }

  Color _getUrgencyColor() {
    switch (_urgencyLevel) {
      case 'High': return _red;
      case 'Medium': return _orange;
      case 'Low': return _green;
      default: return Colors.grey;
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
                                        TextSpan(text: 'Fill your contact details\n\n'),
                                        TextSpan(text: '• ', style: TextStyle(fontWeight: FontWeight.bold)),
                                        TextSpan(text: 'Select urgency level\n\n'),
                                        TextSpan(text: '• ', style: TextStyle(fontWeight: FontWeight.bold)),
                                        TextSpan(text: 'Describe the issue\n\n'),
                                        TextSpan(text: '• ', style: TextStyle(fontWeight: FontWeight.bold)),
                                        TextSpan(text: 'Provide location\n\n'),
                                        TextSpan(text: '• ', style: TextStyle(fontWeight: FontWeight.bold)),
                                        TextSpan(text: 'Add photo (optional)\n\n'),
                                        TextSpan(text: '• ', style: TextStyle(fontWeight: FontWeight.bold)),
                                        TextSpan(text: 'Submit the report'),
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
                              Text('Report an Issue',
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

              // Urgency Level
              _FieldCard(
                label: 'Urgency Level *',
                child: _MenuTile(
                  valueText: _urgencyLevel != null 
                      ? '${_urgencyLevel!} Priority' 
                      : 'Select urgency level…',
                  onTap: _showUrgencyMenu,
                  trailing: _urgencyLevel != null 
                      ? Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getUrgencyColor(),
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
              ),

              // Description
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
                label: 'Location *',
                child: _MenuTile(valueText: _locationChoice ?? 'Select location option…', onTap: _showLocationMenu),
              ),
              
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
                    ],
                  ),
                ),

              if (_showManualLocation)
                _FieldCard(
                  label: 'Enter location manually *',
                  child: TextField(
                    controller: _manualLocation,
                    decoration: const InputDecoration(
                      hintText: 'House no., street, landmark, city…', 
                      border: InputBorder.none
                    ),
                    maxLines: 2,
                  ),
                ),

              // Image Upload
              _FieldCard(
                label: 'Add Photo (Optional)',
                child: Column(
                  children: [
                    if (_selectedImage == null)
                      ElevatedButton.icon(
                        onPressed: _showImageSourceDialog,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Add Photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _indigo.withOpacity(0.1),
                          foregroundColor: _indigo,
                        ),
                      )
                    else
                      Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                height: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: FileImage(_selectedImage!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              if (_isUploadingImage)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black54,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _removeImage,
                            icon: const Icon(Icons.delete),
                            label: const Text('Remove Photo'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    if (_selectedImage == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Take a photo or choose from gallery',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),

              // Submit Button
              Row(
                children: [
                  Expanded(
                    child: _SubmitButton(
                      gradient: [_indigo, _indigoLight],
                      onPressed: _handleSubmit,
                      label: 'Submit Report',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Report Submitted')),
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
                _kv('Urgency', payload['urgency'] ?? '—'),
                if (payload['location'] != null) _kv('Location', payload['location']),
                if (payload['description'] != null) _kv('Description', payload['description']),
                const SizedBox(height: 10),
                if (payload['hasImage'] == true) 
                  _Badge(text: 'Photo attached', icon: Icons.photo),
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
          _TimelineTile(state: 'Under Review', time: '—', isDone: false),
          _TimelineTile(state: 'In Progress', time: '—', isDone: false),
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
        boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
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
  final Widget? trailing; // Add trailing parameter
  
  const _MenuTile({
    required this.valueText, 
    required this.onTap,
    this.trailing, // Make it optional
  });
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(valueText),
      trailing: trailing ?? const Icon(Icons.expand_more_rounded), // Use custom trailing or default icon
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