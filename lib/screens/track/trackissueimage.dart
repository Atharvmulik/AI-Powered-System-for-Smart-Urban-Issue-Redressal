import 'package:flutter/material.dart';
import '../dashboard/correcteddashboard.dart'; // Add this import

class TrackIssuePage extends StatefulWidget {
  final IssueCardData issue;

  const TrackIssuePage({super.key, required this.issue});

  @override
  State<TrackIssuePage> createState() => _TrackIssuePageState();
}

class _TrackIssuePageState extends State<TrackIssuePage> {
  String _filter = 'All'; // 'All', 'Active', 'Resolved'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC), // Beige background
      body: CustomScrollView(
        slivers: [
          // Custom curved header with search and image
          SliverAppBar(
            backgroundColor: Colors.transparent,
            expandedHeight: 280.0, // Increased height for the image
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Curved background
                  _CurvedHeader(
                    color: const Color(0xFF4169E1), // Ultramarine blue
                    heightFactor: 0.85, // Increased curve length
                  ),
                  // Content overlay
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top bar with profile and home icons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Profile icon on top left
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.person, color: Colors.white, size: 20),
                                onPressed: () {
                                  // Navigate to profile page
                                },
                              ),
                            ),
                            // Home icon on top right
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.home, color: Colors.white, size: 20),
                                onPressed: () {
                                  // Navigate to home page
                                  Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(builder: (context) => const DashboardScreen()),
                                      (route) => false,
                                    );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Image and text side by side
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Image on the left
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
                                      child: const Icon(Icons.image, color: Colors.grey),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            // Text on the right
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
                        // Search bar with filter
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Search complaints...',
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                                    hintStyle: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
              child: Wrap(
                spacing: 10,
                children: [
                  _FilterChipCustom(
                    label: 'All',
                    selected: _filter == 'All',
                    onSelected: (bool value) {
                      setState(() {
                        _filter = value ? 'All' : _filter;
                      });
                    },
                  ),
                  _FilterChipCustom(
                    label: 'Active',
                    selected: _filter == 'Active',
                    onSelected: (bool value) {
                      setState(() {
                        _filter = value ? 'Active' : _filter;
                      });
                    },
                  ),
                  _FilterChipCustom(
                    label: 'Resolved',
                    selected: _filter == 'Resolved',
                    onSelected: (bool value) {
                      setState(() {
                        _filter = value ? 'Resolved' : _filter;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // Complaints list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final complaint = _getFilteredComplaints()[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ComplaintCard(
                    title: complaint['title']!,
                    id: complaint['id']!,
                    date: complaint['date']!,
                    status: complaint['status']!,
                    color: _getStatusColor(complaint['status']!),
                    category: complaint['category']!,
                    department: complaint['department']!,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ComplaintDetailsPage(
                            complaint: complaint,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              childCount: _getFilteredComplaints().length,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _getFilteredComplaints() {
    List<Map<String, String>> allComplaints = [
      {
        'title': 'Pothole on MG Road',
        'id': '#12345',
        'date': '31 Aug, 10:15 AM',
        'status': 'In Progress',
        'category': 'Road Maintenance',
        'department': 'Public Works Department',
      },
      {
        'title': 'Water Leakage near Park',
        'id': '#56789',
        'date': '30 Aug, 8:45 AM',
        'status': 'Resolved',
        'category': 'Water Supply',
        'department': 'Water Department',
      },
      {
        'title': 'Streetlight not working',
        'id': '#43210',
        'date': '29 Aug, 7:00 PM',
        'status': 'Assigned',
        'category': 'Electricity',
        'department': 'Electricity Board',
      },
      {
        'title': 'Garbage accumulation',
        'id': '#98765',
        'date': '28 Aug, 3:20 PM',
        'status': 'Submitted',
        'category': 'Sanitation',
        'department': 'Municipal Corporation',
      },
    ];

    if (_filter == 'All') return allComplaints;
    if (_filter == 'Active') {
      return allComplaints.where((complaint) => complaint['status'] != 'Resolved').toList();
    }
    return allComplaints.where((complaint) => complaint['status'] == 'Resolved').toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Submitted':
        return const Color(0xFF9E9E9E);
      case 'Assigned':
        return const Color(0xFF2196F3);
      case 'In Progress':
        return const Color(0xFFFF9800);
      case 'Resolved':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}

class _CurvedHeader extends StatelessWidget {
  final Color color;
  final double heightFactor;

  const _CurvedHeader({
    required this.color,
    this.heightFactor = 0.85,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _CurvedHeaderClipper(heightFactor: heightFactor),
      child: Container(
        color: color,
      ),
    );
  }
}

class _CurvedHeaderClipper extends CustomClipper<Path> {
  final double heightFactor;

  _CurvedHeaderClipper({this.heightFactor = 0.85});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * heightFactor);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * (heightFactor + 0.25), // Increased curve length
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

class ComplaintCard extends StatefulWidget {
  final String title;
  final String id;
  final String date;
  final String status;
  final Color color;
  final String category;
  final String department;
  final VoidCallback onTap;

  const ComplaintCard({
    super.key,
    required this.title,
    required this.id,
    required this.date,
    required this.status,
    required this.color,
    required this.category,
    required this.department,
    required this.onTap,
  });

  @override
  State<ComplaintCard> createState() => _ComplaintCardState();
}

class _ComplaintCardState extends State<ComplaintCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: _hovering ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(_hovering ? 0.15 : 0.05),
                blurRadius: _hovering ? 20.0 : 10.0,
                offset: Offset(0, _hovering ? 8.0 : 4.0),
                spreadRadius: _hovering ? 1.0 : 0.0,
              ),
            ],
            border: Border.all(
              color: Colors.grey.withOpacity(0.1),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF263238),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Text(
                      widget.status,
                      style: TextStyle(
                        color: widget.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              _buildInfoRow(Icons.fingerprint, "Complaint ID: ${widget.id}"),
              const SizedBox(height: 6.0),
              _buildInfoRow(Icons.calendar_today, "Date: ${widget.date}"),
              const SizedBox(height: 6.0),
              _buildInfoRow(Icons.category, "Category: ${widget.category}"),
              const SizedBox(height: 12.0),
              LinearProgressIndicator(
                value: _getProgressValue(widget.status),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(widget.color),
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
        Icon(
          icon,
          size: 16.0,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8.0),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14.0,
          ),
        ),
      ],
    );
  }

  double _getProgressValue(String status) {
    switch (status) {
      case 'Submitted':
        return 0.25;
      case 'Assigned':
        return 0.5;
      case 'In Progress':
        return 0.75;
      case 'Resolved':
        return 1.0;
      default:
        return 0.0;
    }
  }
}

class ComplaintDetailsPage extends StatelessWidget {
  final Map<String, String> complaint;

  const ComplaintDetailsPage({super.key, required this.complaint});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(complaint['title']!),
        backgroundColor: const Color(0xFF4169E1),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Complaint summary card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: Colors.white.withOpacity(0.7),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complaint['title']!,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Complaint ID', complaint['id']!),
                    _buildDetailRow('Submitted on', complaint['date']!),
                    _buildDetailRow('Category', complaint['category']!),
                    _buildDetailRow('Department', complaint['department']!),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getStatusColor(complaint['status']!),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          complaint['status']!,
                          style: TextStyle(
                            color: _getStatusColor(complaint['status']!),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Status Timeline',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTimeline(),
            if (complaint['status'] == 'Resolved') ...[
              const SizedBox(height: 24),
              const Text(
                'Rate Your Experience',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildRatingSection(),
            ],
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
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Column(
      children: [
        _TimelineStep(
          icon: Icons.report_problem,
          color: const Color(0xFF9E9E9E),
          title: 'Complaint Submitted',
          description: 'Your complaint was submitted on ${complaint['date']!}',
          isFirst: true,
          isActive: true,
        ),
        _TimelineStep(
          icon: Icons.assignment,
          color: const Color(0xFF2196F3),
          title: 'Assigned to Department',
          description: 'Assigned to ${complaint['department']!}',
          isActive: complaint['status'] != 'Submitted',
        ),
        _TimelineStep(
          icon: Icons.build,
          color: const Color(0xFFFF9800),
          title: 'Work In Progress',
          description: 'Work is in progress. Expected resolution: 2 Sep',
          isActive: complaint['status'] == 'In Progress' || complaint['status'] == 'Resolved',
        ),
        _TimelineStep(
          icon: Icons.check_circle,
          color: const Color(0xFF4CAF50),
          title: 'Resolved',
          description: 'Issue resolved on 2 Sep, 4:30 PM ✅',
          isLast: true,
          isActive: complaint['status'] == 'Resolved',
        ),
      ],
    );
  }

  Widget _buildRatingSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Colors.white.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'How satisfied are you with the resolution?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [1, 2, 3, 4, 5].map((rating) {
                return IconButton(
                  icon: Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () {
                    // Handle rating
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Submit rating
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4169E1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Submit Feedback'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Submitted':
        return const Color(0xFF9E9E9E);
      case 'Assigned':
        return const Color(0xFF2196F3);
      case 'In Progress':
        return const Color(0xFFFF9800);
      case 'Resolved':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}

class _TimelineStep extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final bool isFirst;
  final bool isLast;
  final bool isActive;

  const _TimelineStep({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    this.isFirst = false,
    this.isLast = false,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            if (!isFirst)
              Container(
                width: 2,
                height: 20,
                color: isActive ? color : Colors.grey[300],
              ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isActive ? color : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 20,
                color: isActive ? color : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isActive ? color : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: isActive ? Colors.black87 : Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

