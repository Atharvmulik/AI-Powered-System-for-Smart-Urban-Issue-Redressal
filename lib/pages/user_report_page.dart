import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';

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

  Future<void> _loadReports({String filter = 'all', String? query}) async {
    try {
      setState(() {
        _isLoading = true;
        _currentFilter = filter;
      });

      final ApiService apiService = ApiService();
      final response = query != null && query.isNotEmpty
          ? await apiService.searchUserReports(widget.userEmail, query)
          : await apiService.getUserReports(widget.userEmail, statusFilter: filter);

      if (mounted) {
        setState(() {
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            _reports = data['complaints'] ?? data['results'] ?? [];
            print('✅ Loaded ${_reports.length} reports');
          } else {
            _reports = [];
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load reports: ${response.statusCode}')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
      appBar: AppBar(
        title: Text('My Complaints'),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search complaints...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: _onSearch,
            ),
          ),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _currentFilter == 'all',
                  onTap: () => _loadReports(filter: 'all'),
                ),
                SizedBox(width: 8),
                _FilterChip(
                  label: 'Active',
                  isSelected: _currentFilter == 'active',
                  onTap: () => _loadReports(filter: 'active'),
                ),
                SizedBox(width: 8),
                _FilterChip(
                  label: 'Resolved',
                  isSelected: _currentFilter == 'resolved',
                  onTap: () => _loadReports(filter: 'resolved'),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Reports List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _reports.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No complaints found',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _reports.length,
                        itemBuilder: (context, index) {
                          final report = _reports[index];
                          return _ReportCard(
                            report: report,
                            // In UserReportsPage - when navigating to timeline:
                            onTap: () {
                              print('📋 Navigating to timeline for report ID: ${report['id']}');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReportTimelinePage(
                                    reportId: report['id'], // Make sure this is an integer
                                    userEmail: widget.userEmail,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback onTap;

  const _ReportCard({
    required this.report,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.teal[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.report_problem, color: Colors.teal[800]),
        ),
        title: Text(
          report['title'] ?? 'No Title',
          style: TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Complaint ID: ${report['complaint_id'] ?? 'N/A'}'),
            Text('Date: ${report['date'] ?? 'N/A'}'),
            Text('Category: ${report['category'] ?? 'General'}'),
          ],
        ),
        trailing: Icon(Icons.chevron_right),
      ),
    );
  }
}

// Replace the placeholder ReportTimelinePage with this real implementation:
class ReportTimelinePage extends StatefulWidget {
  final int reportId;
  final String userEmail;

  const ReportTimelinePage({
    super.key,
    required this.reportId,
    required this.userEmail,
  });

  @override
  State<ReportTimelinePage> createState() => _ReportTimelinePageState();
}

class _ReportTimelinePageState extends State<ReportTimelinePage> {
  Map<String, dynamic>? _reportDetails;
  List<dynamic> _timelineEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReportTimeline();
  }

  Future<void> _loadReportTimeline() async {
  try {
    print('🔄 Loading timeline for report ID: ${widget.reportId}');
    
    final ApiService apiService = ApiService();
    final response = await apiService.getReportTimeline(widget.reportId);
    
    print('📡 Timeline Response Status: ${response.statusCode}');
    
    if (mounted) {
      setState(() {
        if (response.statusCode == 200) {
          try {
            final data = json.decode(response.body);
            print('✅ JSON decoded successfully');
            
            _reportDetails = data['complaint_details'];
            _timelineEvents = data['timeline'] ?? [];
            
            print('📊 Found ${_timelineEvents.length} timeline events');
            print('📝 Report title: ${_reportDetails?['title']}');
            
          } catch (jsonError) {
            print('❌ JSON Parsing Error: $jsonError');
            print('❌ Response body that failed to parse: ${response.body}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error parsing timeline data: $jsonError')),
            );
          }
        } else if (response.statusCode == 500) {
          print('❌ Server Error (500) - Check backend logs');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Server error. Please try again later.')),
          );
        } else {
          print('❌ API Error: ${response.statusCode}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load timeline: ${response.statusCode}')),
          );
        }
        _isLoading = false;
      });
    }
  } catch (e) {
    print('❌ Network Error: $e');
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    }
  }
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Complaint Details'),
      backgroundColor: Colors.teal[800],
      foregroundColor: Colors.white,
    ),
    body: _isLoading
        ? Center(child: CircularProgressIndicator())
        : _reportDetails == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Unable to load complaint details',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadReportTimeline,
                      child: Text('Try Again'),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ComplaintHeader(details: _reportDetails!),
                    SizedBox(height: 24),
                    Text(
                      'Status Timeline',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    _TimelineList(events: _timelineEvents),
                  ],
                ),
              ),
  );
}
}

class _ComplaintHeader extends StatelessWidget {
  final Map<String, dynamic> details;

  const _ComplaintHeader({required this.details});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              details['title'] ?? 'No Title',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            _DetailRow(
              icon: Icons.receipt,
              label: 'Complaint ID:',
              value: details['complaint_id'] ?? 'N/A',
            ),
            _DetailRow(
              icon: Icons.calendar_today,
              label: 'Submitted on:',
              value: details['submitted_on'] ?? 'N/A',
            ),
            _DetailRow(
              icon: Icons.category,
              label: 'Category:',
              value: details['category'] ?? 'General',
            ),
            _DetailRow(
              icon: Icons.business,
              label: 'Department:',
              value: details['department'] ?? 'Public Works Department',
            ),
            _DetailRow(
              icon: Icons.location_on,
              label: 'Location:',
              value: details['location_address'] ?? 'N/A',
            ),
            if (details['urgency_level'] != null)
              _DetailRow(
                icon: Icons.warning,
                label: 'Urgency:',
                value: details['urgency_level'],
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineList extends StatelessWidget {
  final List<dynamic> events;

  const _TimelineList({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(child: Text('No timeline events available'));
    }

    return Column(
      children: events.asMap().entries.map((entry) {
        final index = entry.key;
        final event = entry.value;
        final isLast = index == events.length - 1;

        return _TimelineItem(
          event: event,
          isLast: isLast,
        );
      }).toList(),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final Map<String, dynamic> event;
  final bool isLast;

  const _TimelineItem({
    required this.event,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline line and dot
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getStatusColor(event['status']),
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey[300],
              ),
          ],
        ),
        SizedBox(width: 16),
        
        // Event content
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['event'] ?? 'Unknown Event',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  event['description'] ?? 'No description',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                SizedBox(height: 4),
                Text(
                  _formatTimestamp(event['timestamp']),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }
}