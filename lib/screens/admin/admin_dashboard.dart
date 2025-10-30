import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../pages/report_page.dart';
import '../../pages/view_issue_admin.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  int totalIssues = 1234;
  int resolvedIssues = 890;
  int pendingIssues = 250;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      _buildDashboard(),
      _buildPlaceholderPage("Department Analysis"),
      _buildPlaceholderPage("Issue Reports"),
      _buildPlaceholderPage("Map View"),
      _buildPlaceholderPage("Profile Page"),
    ]);
  }

  void _onNavTapped(int index) {
    if (index == 2) { // Issue Reports index
      // Navigate to ViewIssueAdminPage when Issue Reports is tapped
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const IssueTrackingPage()),
      );
    } else {
      // For other tabs, use the existing page switching
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
              "CivicEye Admin",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 3,
        actions: [
          IconButton(
            onPressed: () {
              // Use direct navigation for logout
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
      body: _pages[_selectedIndex],
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

  // 🌟 Dashboard Page
  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Hello, Vaishnavi 👋",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple)),
                  SizedBox(height: 6),
                  Text("Monitor and manage city issues efficiently",
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

        const SizedBox(height: 20),

        _buildSectionTitle("Monthly Trends"),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _whiteCardDecoration(),
          child: SizedBox(
            height: 220,
            child: LineChart(LineChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                      if (value.toInt() >= 0 && value.toInt() < months.length) {
                        return Text(months[value.toInt()]);
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
                      }),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  color: Colors.deepPurple,
                  barWidth: 3,
                  belowBarData: BarAreaData(
                      show: true,
                      color: Colors.deepPurple.withOpacity(0.1)),
                  spots: const [
                    FlSpot(0, 3),
                    FlSpot(1, 2),
                    FlSpot(2, 4),
                    FlSpot(3, 3.5),
                    FlSpot(4, 4.8),
                    FlSpot(5, 4.2),
                    FlSpot(6, 4.6),
                  ],
                )
              ],
            )),
          ),
        ),
        const SizedBox(height: 20),

        _buildSectionTitle("Department Performance"),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _whiteCardDecoration(),
          child: Column(
            children: [
              _buildDeptPerformanceBar("Public Works", 0.85, Colors.orange),
              _buildDeptPerformanceBar("Sanitation", 0.70, Colors.green),
              _buildDeptPerformanceBar("Traffic", 0.50, Colors.blue),
              _buildDeptPerformanceBar("Parks", 0.60, Colors.purple),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _buildSectionTitle("Issue Breakdown"),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _whiteCardDecoration(),
          child: Column(
            children: [
              SizedBox(
                height: 180,
                child: PieChart(PieChartData(
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                  sections: [
                    _buildPieSection(Colors.teal, 35, "35%"),
                    _buildPieSection(Colors.deepPurple, 25, "25%"),
                    _buildPieSection(Colors.orange, 20, "20%"),
                    _buildPieSection(Colors.blue, 20, "20%"),
                  ],
                )),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                children: const [
                  _Legend(color: Colors.teal, text: "Potholes"),
                  _Legend(color: Colors.deepPurple, text: "Streetlights"),
                  _Legend(color: Colors.orange, text: "Waste"),
                  _Legend(color: Colors.blue, text: "Other"),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 25),

        // 🆕 Recent Reports Section
        _buildSectionTitle("Recent Reports"),
        const SizedBox(height: 10),
        _buildRecentReport("Large pothole on Main St", "Oakland, CA • 2 hours ago",
            "Pending", Colors.orange, Icons.construction_outlined),
        _buildRecentReport("Broken streetlight at 5th & Elm",
            "Springfield, IL • 8 hours ago", "In Progress", Colors.blueAccent,
            Icons.lightbulb_outline),
        _buildRecentReport("Overflowing trash can in City Park",
            "Columbus, OH • 1 day ago", "Resolved", Colors.green,
            Icons.delete_outline),
        _buildRecentReport("Fallen tree blocking side road",
            "Portland, OR • 1 day ago", "Urgent", Colors.redAccent,
            Icons.warning_amber_rounded),
        const SizedBox(height: 20),
      ]),
    );
  }

  // 🔹 Recent Report Card
  Widget _buildRecentReport(
      String title, String subtitle, String status, Color color, IconData icon) {
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
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
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

  // 🔹 Helper Widgets
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
            boxShadow: [
              BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: const Offset(0, 4))
            ],
          ),
          // ✅ Centered alignment inside the card
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

  Widget _buildDeptPerformanceBar(String dept, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(
          flex: 2,
          child: Text(dept,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
        Text("${(value * 100).toStringAsFixed(0)}%",
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 13)),
      ]),
    );
  }

  PieChartSectionData _buildPieSection(Color color, double percent, String title) {
    return PieChartSectionData(
      color: color,
      value: percent,
      radius: 50,
      title: title,
      titleStyle: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
    );
  }

  BoxDecoration _whiteCardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: const Offset(0, 4))
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

class _Legend extends StatelessWidget {
  final Color color;
  final String text;
  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 6),
        Text(text,
            style:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}