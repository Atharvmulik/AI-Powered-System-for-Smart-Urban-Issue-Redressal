import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../screens/dashboard/correcteddashboard.dart';

class UserReportsPage extends StatefulWidget {
  final String userEmail;
  final String userName;

  const UserReportsPage({
    super.key,
    required this.userEmail,
    required this.userName,
  });

  @override
  State<UserReportsPage> createState() => _UserReportsPageState();
}

class _UserReportsPageState extends State<UserReportsPage> {
  List<dynamic> _reports = [];
  bool _isLoading = true;
  String _currentFilter = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReports({String filter = 'all', String? query}) async {
    try {
      setState(() {
        _isLoading = true;
        _currentFilter = filter;
      });

      final ApiService apiService = ApiService();
      final response = query != null && query.isNotEmpty
          ? await apiService.searchUserReports(widget.userEmail, query)
          : await apiService.getUserReports(
              widget.userEmail,
              statusFilter: filter,
            );

      if (mounted) {
        setState(() {
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            _reports = data['complaints'] ?? data['results'] ?? [];
            print('✅ Loaded ${_reports.length} reports');
          } else {
            _reports = [];
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load reports: ${response.statusCode}'),
              ),
            );
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _reports = [];
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      _loadReports(filter: _currentFilter);
    } else {
      _loadReports(query: query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      body: CustomScrollView(
        slivers: [
          // Custom curved header
          SliverAppBar(
            backgroundColor: Colors.transparent,
            expandedHeight: 280.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  _CurvedHeader(
                    color: const Color(0xFF4169E1),
                    heightFactor: 0.85,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _CircleIconButton(
                              icon: Icons.person,
                              onPressed: () {
                                // Navigate to profile
                              },
                            ),
                            _CircleIconButton(
                              icon: Icons.home,
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DashboardScreen(
                                      userEmail: widget.userEmail,
                                      userName: widget.userName,
                                    ),
                                  ),
                                  (route) => false,
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Image and text
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              height: 140,
                              width: 140,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white.withOpacity(0.5),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/images/track_issue_page_image-removebg-preview.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.assignment,
                                        color: Colors.grey,
                                        size: 64,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "My Complaints",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Track your civic issues",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Search bar
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search complaints...',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              hintStyle: TextStyle(color: Colors.grey[600]),
                            ),
                            onChanged: _onSearch,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Filter chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 16.0,
                horizontal: 16.0,
              ),
              child: Wrap(
                spacing: 10,
                children: [
                  _FilterChipCustom(
                    label: 'All',
                    selected: _currentFilter == 'all',
                    onSelected: (bool value) {
                      if (value) _loadReports(filter: 'all');
                    },
                  ),
                  _FilterChipCustom(
                    label: 'Active',
                    selected: _currentFilter == 'active',
                    onSelected: (bool value) {
                      if (value) _loadReports(filter: 'active');
                    },
                  ),
                  _FilterChipCustom(
                    label: 'Resolved',
                    selected: _currentFilter == 'resolved',
                    onSelected: (bool value) {
                      if (value) _loadReports(filter: 'resolved');
                    },
                  ),
                ],
              ),
            ),
          ),

          // Content
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF4169E1),
                    ),
                  ),
                ),
              ),
            )
          else if (_reports.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No complaints found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((
                BuildContext context,
                int index,
              ) {
                final report = _reports[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: _ComplaintCard(
                    report: report,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReportDetailsPage(
                            reportId: report['id'],
                            userEmail: widget.userEmail,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }, childCount: _reports.length),
            ),
        ],
      ),
    );
  }
}

// Circle Icon Button Widget
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircleIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

// Curved Header Widget
class _CurvedHeader extends StatelessWidget {
  final Color color;
  final double heightFactor;

  const _CurvedHeader({required this.color, this.heightFactor = 0.85});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _CurvedHeaderClipper(heightFactor: heightFactor),
      child: Container(color: color),
    );
  }
}

// Curved Header Clipper
class _CurvedHeaderClipper extends CustomClipper<Path> {
  final double heightFactor;

  _CurvedHeaderClipper({this.heightFactor = 0.85});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * heightFactor);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * (heightFactor + 0.25),
      size.width,
      size.height * heightFactor,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Filter Chip Widget
class _FilterChipCustom extends StatelessWidget {
  final String label;
  final bool selected;
  final Function(bool) onSelected;

  const _FilterChipCustom({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: Colors.white.withOpacity(0.7),
      selectedColor: const Color(0xFF4169E1).withOpacity(0.2),
      checkmarkColor: const Color(0xFF4169E1),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF4169E1) : Colors.grey[700],
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: selected ? const Color(0xFF4169E1) : Colors.grey[300]!,
          width: 1.0,
        ),
      ),
    );
  }
}

// Complaint Card Widget
class _ComplaintCard extends StatefulWidget {
  final Map<String, dynamic> report;
  final VoidCallback onTap;

  const _ComplaintCard({required this.report, required this.onTap});

  @override
  State<_ComplaintCard> createState() => _ComplaintCardState();
}

class _ComplaintCardState extends State<_ComplaintCard> {
  bool _hovering = false;

  String _getStatusText(String status) {
    switch (status) {
      case 'submitted':
        return 'Submitted';
      case 'assigned':
        return 'Assigned';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      default:
        return 'Submitted';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'submitted':
        return const Color(0xFF9E9E9E);
      case 'assigned':
        return const Color(0xFF2196F3);
      case 'in_progress':
        return const Color(0xFFFF9800);
      case 'resolved':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  double _getProgressValue(String status) {
    switch (status) {
      case 'submitted':
        return 0.25;
      case 'assigned':
        return 0.5;
      case 'in_progress':
        return 0.75;
      case 'resolved':
        return 1.0;
      default:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.report['status'] ?? 'submitted';
    final statusText = _getStatusText(status);
    final statusColor = _getStatusColor(status);
    final progressValue = _getProgressValue(status);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: _hovering
                ? Colors.white.withOpacity(0.9)
                : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(_hovering ? 0.15 : 0.05),
                blurRadius: _hovering ? 20.0 : 10.0,
                offset: Offset(0, _hovering ? 8.0 : 4.0),
                spreadRadius: _hovering ? 1.0 : 0.0,
              ),
            ],
            border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.report['title'] ?? 'No Title',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF263238),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 6.0,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              _buildInfoRow(
                Icons.fingerprint,
                "Complaint ID: ${widget.report['complaint_id'] ?? 'N/A'}",
              ),
              const SizedBox(height: 6.0),
              _buildInfoRow(
                Icons.calendar_today,
                "Date: ${widget.report['date'] ?? 'N/A'}",
              ),
              const SizedBox(height: 6.0),
              _buildInfoRow(
                Icons.category,
                "Category: ${widget.report['category'] ?? 'General'}",
              ),
              const SizedBox(height: 12.0),
              LinearProgressIndicator(
                value: progressValue,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                borderRadius: BorderRadius.circular(10.0),
                minHeight: 8.0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16.0, color: Colors.grey[600]),
        const SizedBox(width: 8.0),
        Text(text, style: TextStyle(color: Colors.grey[700], fontSize: 14.0)),
      ],
    );
  }
}

// Report Details Page (WITHOUT Timeline Section and Share Button)
class ReportDetailsPage extends StatefulWidget {
  final int reportId;
  final String userEmail;

  const ReportDetailsPage({
    super.key,
    required this.reportId,
    required this.userEmail,
  });

  @override
  State<ReportDetailsPage> createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage> {
  Map<String, dynamic>? _reportDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReportDetails();
  }

  Future<void> _loadReportDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final ApiService apiService = ApiService();
      print('🔄 Starting details fetch for report ID: ${widget.reportId}');

      final response = await apiService.getReportTimeline(widget.reportId);

      print('📥 Received response with status: ${response.statusCode}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          print('✅ Successfully decoded JSON');
          print('📦 Data keys: ${data.keys}');

          setState(() {
            _reportDetails = data['complaint_details'];
            _isLoading = false;
          });

          print('✅ Details loaded successfully');
        } catch (e) {
          print('❌ JSON parsing error: $e');
          setState(() {
            _isLoading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error parsing complaint data: $e')),
            );
          }
        }
      } else {
        print('❌ Server error: ${response.statusCode}');
        print('❌ Error body: ${response.body}');

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to load details. Status: ${response.statusCode}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Network error in details: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: const Text('Complaint Details'),
        backgroundColor: const Color(0xFF4169E1),
        foregroundColor: Colors.white,
        // ✅ REMOVED share button from actions
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reportDetails == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Unable to load complaint details',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadReportDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4169E1),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ComplaintDetailsCard(details: _reportDetails!),
                      // ✅ REMOVED Status Timeline section completely
                    ],
                  ),
                ),
    );
  }
}

// Complaint Details Card (same as before)
class _ComplaintDetailsCard extends StatelessWidget {
  final Map<String, dynamic> details;

  const _ComplaintDetailsCard({required this.details});

  String _getStatusText(String status) {
    switch (status) {
      case 'submitted':
        return 'Submitted';
      case 'assigned':
        return 'Assigned';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      default:
        return 'Submitted';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'submitted':
        return const Color(0xFF9E9E9E);
      case 'assigned':
        return const Color(0xFF2196F3);
      case 'in_progress':
        return const Color(0xFFFF9800);
      case 'resolved':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              details['title'] ?? 'No Title',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Complaint ID', details['complaint_id'] ?? 'N/A'),
            _buildDetailRow('Submitted on', details['submitted_on'] ?? 'N/A'),
            _buildDetailRow('Category', details['category'] ?? 'General'),
            _buildDetailRow(
              'Department',
              details['department'] ?? 'Public Works Department',
            ),
            if (details['location_address'] != null)
              _buildDetailRow('Location', details['location_address']!),
            if (details['urgency_level'] != null)
              _buildDetailRow('Urgency', details['urgency_level']!),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getStatusColor(details['status'] ?? 'submitted'),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getStatusText(details['status'] ?? 'submitted'),
                  style: TextStyle(
                    color: _getStatusColor(details['status'] ?? 'submitted'),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}