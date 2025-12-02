import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import '../../services/api_service.dart';
import '../../pages/report_page.dart';
import '../../pages/view_issue_admin.dart';
import '../../pages/dept_analysis.dart';
import '../../pages/admin_profile.dart';
import '../../pages/map_view.dart';

class AdminDashboardPage extends StatefulWidget {
  final String userEmail;
  final String userName;
  
  const AdminDashboardPage({
    super.key,
    required this.userEmail,
    required this.userName,
  });

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  
  int totalIssues = 0;
  int resolvedIssues = 0;
  int pendingIssues = 0;
  bool isLoading = true;
  String? errorMessage;
  final ApiService apiService = ApiService();
  
  List<dynamic> monthlyTrends = [];
  List<dynamic> departmentPerformance = [];
  List<dynamic> recentReports = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      print('🔄 Starting dashboard data load...');

      await _loadStatsData();
      await _loadMonthlyTrends();
      await _loadDepartmentPerformance();
      await _loadRecentReports();

      print('✅ Dashboard data loaded successfully');
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading dashboard data: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load dashboard data: ${e.toString()}';
      });
    }
  }

  Future<void> _loadStatsData() async {
    try {
      print('📊 Loading stats data...');
      final response = await apiService.getAdminDashboardStats();
      
      print('Stats Response Status: ${response.statusCode}');
      print('Stats Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          totalIssues = data['total_issues'] ?? 0;
          resolvedIssues = data['resolved_issues'] ?? 0;
          pendingIssues = data['pending_issues'] ?? 0;
        });
        print('✅ Stats loaded: Total=$totalIssues, Resolved=$resolvedIssues, Pending=$pendingIssues');
      } else {
        print('⚠️ Stats API returned status ${response.statusCode}');
        throw Exception('Failed to load stats: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading stats: $e');
      setState(() {
        totalIssues = 0;
        resolvedIssues = 0;
        pendingIssues = 0;
      });
    }
  }

  Future<void> _loadMonthlyTrends() async {
    try {
      print('📈 Loading monthly trends...');
      final response = await apiService.getMonthlyTrends();
      
      print('Trends Response Status: ${response.statusCode}');
      print('Trends Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          monthlyTrends = data['monthly_trends'] ?? [];
        });
        print('✅ Monthly trends loaded: ${monthlyTrends.length} months');
      } else {
        print('⚠️ Trends API returned status ${response.statusCode}');
        throw Exception('Failed to load trends');
      }
    } catch (e) {
      print('❌ Error loading monthly trends: $e');
      setState(() {
        monthlyTrends = [
          {"month": "Jan", "issues": 45},
          {"month": "Feb", "issues": 52},
          {"month": "Mar", "issues": 48},
          {"month": "Apr", "issues": 61},
          {"month": "May", "issues": 55},
          {"month": "Jun", "issues": 58}
        ];
      });
    }
  }

  Future<void> _loadDepartmentPerformance() async {
    try {
      print('🏢 Loading department performance...');
      final response = await apiService.getDepartmentPerformance();
      
      print('Dept Performance Response Status: ${response.statusCode}');
      print('Dept Performance Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          departmentPerformance = data['departments'] ?? [];
        });
        print('✅ Department performance loaded: ${departmentPerformance.length} departments');
      } else {
        print('⚠️ Dept Performance API returned status ${response.statusCode}');
        throw Exception('Failed to load department performance');
      }
    } catch (e) {
      print('❌ Error loading department performance: $e');
      setState(() {
        departmentPerformance = [];
      });
    }
  }

  Future<void> _loadRecentReports() async {
    try {
      print('📋 Loading recent reports...');
      final response = await apiService.getRecentReports(limit: 4);
      
      print('Recent Reports Response Status: ${response.statusCode}');
      print('Recent Reports Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          recentReports = data['recent_reports'] ?? [];
        });
        print('✅ Recent reports loaded: ${recentReports.length} reports');
      } else {
        print('⚠️ Recent Reports API returned status ${response.statusCode}');
        throw Exception('Failed to load recent reports');
      }
    } catch (e) {
      print('❌ Error loading recent reports: $e');
      setState(() {
        recentReports = [];
      });
    }
  }

  void _onNavTapped(int index) {
    if (index == 4) { 
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfilePage(
            userEmail: widget.userEmail,
            userName: widget.userName,
          ),
        ),
      );
    }  
    else if (index == 3) { 
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminMapViewPage()),
      );
    }
    else if (index == 2) { 
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const IssueTrackingPage()),
      );
    } else if (index == 1) { 
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DepartmentAnalysisPage()),
      );
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "UrbanSim AI",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 3,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginSignupPage()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: _getCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined), label: 'Dept Analysis'),
          BottomNavigationBarItem(
              icon: Icon(Icons.report_outlined), label: 'Issue Reports'),
          BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined), label: 'Map View'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _getCurrentPage() {
    if (_selectedIndex == 0) {
      return _buildDashboard();
    } else {
      return _buildPlaceholderPage("Page ${_selectedIndex + 1}");
    }
  }

  Widget _buildDashboard() {
    if (errorMessage != null && !isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Dashboard',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white,
                child: Icon(Icons.admin_panel_settings_rounded,
                    color: Colors.deepPurple, size: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Hello, ${widget.userName.split(' ').last} 👋",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple
                      )
                    ),
                    const SizedBox(height: 6),
                    const Text("Monitor and manage city issues efficiently",
                        style: TextStyle(
                            color: Colors.black54,
                            fontSize: 15,
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              )
            ]),
          ),
          const SizedBox(height: 40),

          if (isLoading)
            _buildLoadingStats()
          else
            _buildStatsCards(),

          const SizedBox(height: 20),

          _buildSectionTitle("Monthly Trends"),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _whiteCardDecoration(),
            child: SizedBox(
              height: 220,
              child: monthlyTrends.isEmpty 
                  ? _buildLoadingChart()
                  : _buildMonthlyTrendsChart(),
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionTitle("Department Performance"),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _whiteCardDecoration(),
            child: departmentPerformance.isEmpty
                ? _buildEmptyDepartmentPerformance()
                : _buildDepartmentPerformanceList(),
          ),
          const SizedBox(height: 20),

          _buildSectionTitle("Recent Reports"),
          const SizedBox(height: 10),
          recentReports.isEmpty
              ? _buildEmptyRecentReports()
              : _buildRecentReportsList(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLoadingStats() {
    return Column(
      children: [
        Row(
          children: [
            _buildLoadingCard(),
            _buildLoadingCard(),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 180, child: _buildLoadingCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(16),
        decoration: _whiteCardDecoration(),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(height: 8),
            Text("Loading...", 
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Column(
      children: [
        Row(
          children: [
            _buildAnimatedCard("Total Issues", totalIssues, "+15% vs last month",
                Colors.deepPurple, Icons.task_alt_rounded),
            _buildAnimatedCard("Resolved", resolvedIssues, "+20%", Colors.green,
                Icons.verified_outlined),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 180,
              child: _buildAnimatedCard(
                "Pending",
                pendingIssues,
                "-5%",
                Colors.orange,
                Icons.pending_actions,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthlyTrendsChart() {
    final spots = monthlyTrends.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      return FlSpot(index.toDouble(), (data['issues'] ?? 0).toDouble());
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < monthlyTrends.length) {
                  return Text(monthlyTrends[value.toInt()]['month'] ?? '');
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString());
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: Colors.deepPurple,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: Colors.deepPurple.withOpacity(0.1)
            ),
            spots: spots,
          )
        ],
      ),
    );
  }

  Widget _buildLoadingChart() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 10),
          Text("Loading trends...", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDepartmentPerformanceList() {
    return Column(
      children: departmentPerformance.map((dept) {
        final progress = (dept['progress'] ?? 0.0).toDouble();
        final progressPercent = (progress * 100).toInt();
        final color = _getDepartmentColor(progress);
        
        return _buildDeptPerformanceBar(
          dept['department'] ?? 'Unknown Department',
          progress,
          color,
          progressPercent,
        );
      }).toList(),
    );
  }

  Widget _buildEmptyDepartmentPerformance() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Text(
          "No department data available",
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ),
    );
  }

  Color _getDepartmentColor(double progress) {
    if (progress >= 0.8) return Colors.green;
    if (progress >= 0.6) return Colors.blue;
    if (progress >= 0.4) return Colors.orange;
    return Colors.red;
  }

  Widget _buildDeptPerformanceBar(String dept, double value, Color color, int percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(
          flex: 2,
          child: Text(dept,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          flex: 4,
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey.shade200,
            color: color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 8),
        Text("$percent%",
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 13)),
      ]),
    );
  }

  Widget _buildRecentReportsList() {
    return Column(
      children: recentReports.map((report) {
        return _buildRecentReport(
          report['title'] ?? 'No Title',
          report['location'] ?? 'Location not specified',
          report['status'] ?? 'Pending',
          _getStatusColor(report['status']),
          _getStatusIcon(report['status']),
          report['time_ago'] ?? 'Recently',
        );
      }).toList(),
    );
  }

  Widget _buildEmptyRecentReports() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: _whiteCardDecoration(),
      child: const Center(
        child: Text(
          "No recent reports available",
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'in progress':
        return Colors.blue;
      case 'urgent':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'resolved':
        return Icons.check_circle_outline;
      case 'in progress':
        return Icons.build_circle_outlined;
      case 'urgent':
        return Icons.warning_amber_rounded;
      default:
        return Icons.pending_actions;
    }
  }

  Widget _buildRecentReport(
      String title, String subtitle, String status, Color color, IconData icon, String timeAgo) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: _whiteCardDecoration(),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text("$subtitle • $timeAgo", style: const TextStyle(fontSize: 13)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(status,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(
      String title, dynamic value, String change, Color color, IconData icon) {
    return Expanded(
      child: InkWell(
        onTap: () {},
        onHover: (_) => setState(() {}),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4))
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54)),
              const SizedBox(height: 4),
              Text("$value",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color)),
              if (change.isNotEmpty)
                Text(change,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        color: color.withOpacity(0.8),
                        fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _whiteCardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 4))
        ],
      );

  Widget _buildSectionTitle(String title) => Text(title,
      style: const TextStyle(
          fontSize: 20, fontWeight: FontWeight.w700, color: Colors.deepPurple));

  Widget _buildPlaceholderPage(String title) {
    return Center(
      child: Text(title,
          style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple)),
    );
  }
}