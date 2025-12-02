import 'dart:convert';
import 'package:flutter/material.dart';
import '../guide/guide.dart';
import '../report/issuereport.dart' as report;
import '../../services/api_service.dart';
import '../../pages/user_profile.dart';
import '../../pages/user_report_page.dart';
import '../../pages/map_view.dart';

class DashboardScreen extends StatefulWidget {
  final String userEmail;
  final String userName;

  const DashboardScreen({
    super.key,
    required this.userEmail,
    required this.userName,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> reportedIssues = [];
  bool isLoading = true;
  int _bottomIndex = 0;

  final categories = const [
    _IssueCategory('Pothole', Icons.traffic),
    _IssueCategory('Water', Icons.water_drop),
    _IssueCategory('Garbage', Icons.delete_outline),
    _IssueCategory('Lights', Icons.light_mode_outlined),
  ];

  void _showGuideOverlay() {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => GuideOverlay(
        onFinish: () {
          overlayEntry.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);
  }

  @override
  void initState() {
    super.initState();
    _loadIssues();
  }

  void _loadIssues() async {
    try {
      print('🔄 Loading issues for user: ${widget.userEmail}');
      final ApiService apiService = ApiService();
      final response = await apiService.getUserReports(
        widget.userEmail,
        statusFilter: 'all',
      );

      print('📡 Response status: ${response.statusCode}');
      print(
        '📦 Full response: ${response.body}',
      ); 
      if (mounted) {
        setState(() {
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            reportedIssues = data['complaints'] ?? [];
            print('✅ Successfully loaded ${reportedIssues.length} issues');

            // Debug: Print each issue to see the actual data structure
            for (var i = 0; i < reportedIssues.length; i++) {
              print('📝 Issue $i: ${reportedIssues[i]}');
            }
          } else {
            reportedIssues = [];
            print('❌ Failed to load issues: ${response.statusCode}');
          }
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading issues: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          reportedIssues = [];
        });
      }
    }
  }

  double _getUrgencyValue(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
        return 0.9;
      case 'medium':
        return 0.6;
      case 'low':
        return 0.3;
      default:
        return 0.5;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.teal[800],
        title: Row(
          children: [
            const Icon(
              Icons.radio_button_checked,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'UrbanSim AI',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showGuideOverlay,
            icon: const Icon(
              Icons.help_outline,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        UserProfilePage(userEmail: widget.userEmail),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Text(
                  widget.userName.isNotEmpty
                      ? widget.userName[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: Colors.teal[800],
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _greetingCard(cs),
            const SizedBox(height: 12),
            _reportedSection(cs),
            const SizedBox(height: 18),
            _reportIssueSection(cs),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomIndex,
        onDestinationSelected: (index) {
          // Handle navigation based on selected index
          switch (index) {
            case 0: // Home - already on dashboard
              setState(() => _bottomIndex = index);
              break;
            case 1: // Report
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const report.ReportIssuePage(),
                ),
              );
              // Reset to home after navigation
              Future.delayed(Duration.zero, () {
                if (mounted) {
                  setState(() => _bottomIndex = 0);
                }
              });
              break;
            case 2: // Profile
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfilePage(userEmail: widget.userEmail),
                ),
              );
              // Reset to home after navigation
              Future.delayed(Duration.zero, () {
                if (mounted) {
                  setState(() => _bottomIndex = 0);
                }
              });
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(icon: Icon(Icons.add), label: 'Report'),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const report.ReportIssuePage()),
          );
        },
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Report issue'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _greetingCard(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal[800],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${widget.userName}! ',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Make your city better today',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _quickChip('Track', Icons.location_on, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserReportsPage(
                            userEmail: widget.userEmail,
                            userName: widget.userName,
                          ),
                        ),
                      );
                    }),
                    _quickChip('Nearby Issues', Icons.receipt_long, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminMapViewPage(),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.map_outlined, size: 50, color: Colors.white),
        ],
      ),
    );
  }

  Widget _reportedSection(ColorScheme cs) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Reported issues',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadIssues),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 180,
          child: reportedIssues.isEmpty
              ? const Center(child: Text('No issues reported yet'))
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: reportedIssues.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final issue = reportedIssues[index];
                    return _IssueCard(
                      data: IssueCardData(
                        title: issue['title'] ?? 'No title',
                        type: issue['category'] ?? 'General',
                        urgency: _getUrgencyValue(
                          issue['urgency_level'] ?? 'medium',
                        ),
                        distanceKm: 0.5,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserReportsPage(
                              userEmail: widget.userEmail,
                              userName: widget.userName,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _reportIssueSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Report issue',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final c in categories)
              _CategoryTile(
                category: c,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const report.ReportIssuePage(),
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _quickChip(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: Colors.teal.shade800),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.teal.shade200),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({required this.data, required this.onTap});
  final IssueCardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: 260,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.place, size: 18, color: Colors.teal),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                _UrgencyPill(value: data.urgency),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 16,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 6),
                Text(data.type, style: TextStyle(color: Colors.grey.shade800)),
                const Spacer(),
                Icon(
                  Icons.directions_walk,
                  size: 16,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  '${data.distanceKm.toStringAsFixed(1)} km',
                  style: TextStyle(color: Colors.grey.shade800),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UrgencyPill extends StatelessWidget {
  const _UrgencyPill({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    Color bg;
    if (value > 0.75) {
      bg = Colors.red.shade600;
    } else if (value > 0.5) {
      bg = Colors.orange.shade600;
    } else {
      bg = Colors.green.shade600;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Text(
        'Urgency',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class IssueCardData {
  IssueCardData({
    required this.title,
    required this.type,
    required this.urgency,
    required this.distanceKm,
  });
  final String title;
  final String type;
  final double urgency;
  final double distanceKm;
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});
  final _IssueCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.teal.shade100,
            border: Border.all(color: Colors.blue.shade200, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(category.icon, color: Colors.blue.shade400),
              const SizedBox(height: 6),
              Text(
                category.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IssueCategory {
  const _IssueCategory(this.title, this.icon);
  final String title;
  final IconData icon;
}

// Placeholder classes for navigation (you'll need to implement these)
class TrackIssuesPage extends StatelessWidget {
  final String userEmail;

  const TrackIssuesPage({super.key, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Track My Issues')),
      body: Center(child: Text('Track Issues Page for $userEmail')),
    );
  }
}

class NearbyIssuesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nearby Issues')),
      body: Center(child: Text('Nearby Issues Page')),
    );
  }
}