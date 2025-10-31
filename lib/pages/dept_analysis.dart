// analytics_page.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import 'dart:convert';

class DepartmentAnalysisPage extends StatefulWidget {
  const DepartmentAnalysisPage({super.key});

  @override
  State<DepartmentAnalysisPage> createState() => _DepartmentAnalysisPageState();
}

class _DepartmentAnalysisPageState extends State<DepartmentAnalysisPage> {
  String selectedDept = "All Departments";
  String selectedPeriod = "This Month";
  bool isLoading = true;
  List<dynamic> departments = [];
  List<dynamic> departmentIssues = [];
  List<dynamic> resolutionTrends = [];

  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadDepartmentData();
  }

  Future<void> _loadDepartmentData() async {
  try {
    setState(() {
      isLoading = true;
    });

    // Load departments summary
    final departmentsResponse = await apiService.getDepartmentsSummary(period: _getPeriodParam());
    if (departmentsResponse.statusCode == 200) {
      final data = json.decode(departmentsResponse.body);
      print('📊 Departments summary data: $data');
      
      // SAFE CONVERSION: Handle both int and double values
      final List<dynamic> rawDepartments = data['departments'] ?? data['data'] ?? [];
      final List<dynamic> processedDepartments = rawDepartments.map((dept) {
        return {
          'id': dept['id'] is int ? dept['id'] : int.tryParse(dept['id'].toString()) ?? 0,
          'name': dept['name']?.toString() ?? 'Unknown',
          'icon': dept['icon']?.toString() ?? 'build',
          'resolved': dept['resolved'] is int ? dept['resolved'] : int.tryParse(dept['resolved'].toString()) ?? 0,
          'pending': dept['pending'] is int ? dept['pending'] : int.tryParse(dept['pending'].toString()) ?? 0,
          'progress': dept['progress'] is int ? dept['progress'] : int.tryParse(dept['progress'].toString()) ?? 0,
          'efficiency': dept['efficiency'] is double ? dept['efficiency'] : 
                       dept['efficiency'] is int ? dept['efficiency'].toDouble() : 
                       double.tryParse(dept['efficiency'].toString()) ?? 0.0,
          'total_issues': dept['total_issues'] is int ? dept['total_issues'] : 
                         int.tryParse(dept['total_issues'].toString()) ?? 0,
        };
      }).toList();
      
      setState(() {
        departments = processedDepartments;
      });
    } else {
      print('❌ Departments API error: ${departmentsResponse.statusCode}');
    }

    // Load department issues for bar chart
    final issuesResponse = await apiService.getDepartmentIssues(period: _getPeriodParam());
    if (issuesResponse.statusCode == 200) {
      final data = json.decode(issuesResponse.body);
      print('📊 Department issues data: $data');
      
      // SAFE CONVERSION for chart data
      final List<dynamic> rawIssues = data['data'] ?? data['department_issues'] ?? [];
      final List<dynamic> processedIssues = rawIssues.map((issue) {
        return {
          'department': issue['department']?.toString() ?? 'Unknown',
          'issues_count': issue['issues_count'] is int ? issue['issues_count'].toDouble() : 
                         issue['issues_count'] is double ? issue['issues_count'] : 
                         double.tryParse(issue['issues_count'].toString()) ?? 0.0,
        };
      }).toList();
      
      setState(() {
        departmentIssues = processedIssues;
      });
    } else {
      print('❌ Issues API error: ${issuesResponse.statusCode}');
    }

    // Load resolution trends
    final trendsResponse = await apiService.getResolutionTrends(period: _getPeriodParam());
    if (trendsResponse.statusCode == 200) {
      final data = json.decode(trendsResponse.body);
      print('📊 Resolution trends data: $data');
      
      // SAFE CONVERSION for trend data
      final List<dynamic> rawTrends = data['trends'] ?? data['data'] ?? [];
      final List<dynamic> processedTrends = rawTrends.map((trend) {
        return {
          'department': trend['department']?.toString() ?? 'Unknown',
          'months': trend['months'] is List ? trend['months'] : [],
          'data': trend['data'] is List ? (trend['data'] as List).map((item) {
            return item is double ? item : 
                   item is int ? item.toDouble() : 
                   double.tryParse(item.toString()) ?? 0.0;
          }).toList() : [],
        };
      }).toList();
      
      setState(() {
        resolutionTrends = processedTrends;
      });
    } else {
      print('❌ Trends API error: ${trendsResponse.statusCode}');
    }
  } catch (e) {
    print('❌ Error loading department data: $e');
    // Fallback to empty data
    setState(() {
      departments = [];
      departmentIssues = [];
      resolutionTrends = [];
    });
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}
  String _getPeriodParam() {
    switch (selectedPeriod) {
      case "This Week":
        return "week";
      case "This Month":
        return "month";
      case "This Year":
        return "year";
      default:
        return "month";
    }
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case "water_drop":
        return Icons.water_drop;
      case "traffic":
        return Icons.traffic;
      case "clean_hands":
        return Icons.clean_hands;
      case "lightbulb":
        return Icons.lightbulb;
      case "engineering":
        return Icons.engineering;
      default:
        return Icons.build;
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF4361EE);
    const secondaryColor = Color(0xFF3A0CA3);
    const backgroundColor = Color(0xFFF8F9FA);
    const textPrimary = Color(0xFF2B2D42);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Modern Header
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: const Icon(
                            Icons.analytics_outlined,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Department Analysis",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Track performance and efficiency",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Modern Filter Row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: DropdownButton<String>(
                              value: selectedDept,
                              isExpanded: true,
                              underline: const SizedBox(),
                              icon: const Icon(Icons.expand_more, color: Colors.white70, size: 20),
                              dropdownColor: secondaryColor,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                              items: ["All Departments", "Water Dept", "Road Dept", "Sanitation Dept", "Electricity Dept"]
                                  .map((e) => DropdownMenuItem<String>(
                                        value: e,
                                        child: Text(e),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(() => selectedDept = v!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: DropdownButton<String>(
                              value: selectedPeriod,
                              isExpanded: true,
                              underline: const SizedBox(),
                              icon: const Icon(Icons.expand_more, color: Colors.white70, size: 20),
                              dropdownColor: secondaryColor,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                              items: ["This Week", "This Month", "This Year"]
                                  .map((e) => DropdownMenuItem<String>(
                                        value: e,
                                        child: Text(e),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                setState(() => selectedPeriod = v!);
                                _loadDepartmentData();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Department Cards Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: isLoading
                    ? _buildLoadingGrid()
                    : GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                        children: departments.map((dept) => _buildModernDepartmentCard(
                          id: dept['id'],
                          name: dept['name'],
                          icon: _getIconFromString(dept['icon']),
                          resolved: dept['resolved'],
                          pending: dept['pending'],
                          progress: dept['progress'],
                          efficiency: dept['efficiency'],
                          totalIssues: dept['total_issues'],
                        )).toList(),
                      ),
              ),

              const SizedBox(height: 24),

              // Charts Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: Text(
                        "Performance Overview",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    
                    // Bar Chart
                    Container(
                      decoration: _modernCardDecoration(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Issues by Department",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 240,
                            child: _OverviewBarChart(departmentIssues: departmentIssues),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Resolution Trend Analysis Chart
                    Container(
                      decoration: _modernCardDecoration(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Resolution Trend Analysis",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: _ResolutionTrendChart(resolutionTrends: resolutionTrends),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.85,
      children: List.generate(4, (index) => buildLoadingCard()),
    );
  }

  Widget buildLoadingCard() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF1F1F1F).withOpacity(0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(radius: 22, backgroundColor: Color(0xFFE5E7EB)),
              Container(
                width: 40,
                height: 24,
                decoration: BoxDecoration(
                  color: Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 16,
            color: Color(0xFFE5E7EB),
          ),
          const SizedBox(height: 6),
          Container(
            width: 60,
            height: 12,
            color: Color(0xFFE5E7EB),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: 0.5,
            backgroundColor: Color(0xFFF3F4F6),
            color: Color(0xFFD1D5DB),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LoadingMiniStat(),
              _LoadingMiniStat(),
              _LoadingMiniStat(),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildModernDepartmentCard({
    required int id,
    required String name,
    required IconData icon,
    required int resolved,
    required int pending,
    required int progress,
    required double efficiency,
    required int totalIssues,
  }) {
    double successRate = (resolved / (totalIssues == 0 ? 1 : totalIssues)) * 100;

    Color efficiencyColor = efficiency >= 85 ? const Color(0xFF4ADE80) : 
                           efficiency >= 70 ? const Color(0xFFF59E0B) : 
                           const Color(0xFFEF4444);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DepartmentDetailPage(
              deptId: id,
              name: name,
              icon: icon,
              resolved: resolved,
              pending: pending,
              progress: progress,
              efficiency: efficiency,
              totalIssues: totalIssues,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1F1F1F).withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4361EE), Color(0xFF3A0CA3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4361EE).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, size: 22, color: Colors.white),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: efficiencyColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: efficiencyColor.withOpacity(0.2)),
                    ),
                    child: Text(
                      "${efficiency.toStringAsFixed(0)}%",
                      style: TextStyle(
                        color: efficiencyColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2B2D42),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "$totalIssues Issues",
                style: const TextStyle(
                  color: Color(0xFF8D99AE),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: (successRate / 100).clamp(0.0, 1.0),
                backgroundColor: Colors.grey.withOpacity(0.2),
                color: efficiencyColor,
                borderRadius: BorderRadius.circular(10),
                minHeight: 6,
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniStat("Resolved", resolved, const Color(0xFF4ADE80)),
                  _buildMiniStat("Pending", pending, const Color(0xFFF59E0B)),
                  _buildMiniStat("Progress", progress, const Color(0xFF3B82F6)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF8D99AE),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  BoxDecoration _modernCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF1F1F1F).withOpacity(0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
      border: Border.all(color: Colors.grey.withOpacity(0.08)),
    );
  }
}

class _LoadingMiniStat extends StatelessWidget {
  const _LoadingMiniStat();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 15,
          color: Color(0xFFE5E7EB),
        ),
        const SizedBox(height: 2),
        Container(
          width: 30,
          height: 10,
          color: Color(0xFFE5E7EB),
        ),
      ],
    );
  }
}

// ---------------- Overview Bar Chart (Enhanced) ----------------
class _OverviewBarChart extends StatelessWidget {
  final List<dynamic> departmentIssues;
  const _OverviewBarChart({required this.departmentIssues});

  @override
  Widget build(BuildContext context) {
    try {
      if (departmentIssues.isEmpty) {
        return _buildEmptyState();
      }

      // EXTRA SAFE conversion
      final List<double> data = departmentIssues.map((d) {
        try {
          final value = d['issues_count'];
          if (value == null) return 0.0;
          if (value is int) return value.toDouble();
          if (value is double) return value;
          if (value is num) return value.toDouble();
          if (value is String) return double.tryParse(value) ?? 0.0;
          return 0.0;
        } catch (e) {
          print('❌ Error converting chart value: $e');
          return 0.0;
        }
      }).toList();
      
      final labels = departmentIssues.map((d) {
        try {
          final dept = d['department'];
          return dept is String ? dept : dept?.toString() ?? 'Unknown';
        } catch (e) {
          return 'Unknown';
        }
      }).toList();
      
      if (data.isEmpty || data.every((element) => element == 0)) {
        return _buildEmptyState();
      }
      
      final maxValue = data.reduce((a, b) => a > b ? a : b);

      return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue + 8,
          barGroups: List.generate(data.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: data[index],
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4361EE), Color(0xFF4CC9F0)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 20,
                  borderRadius: BorderRadius.circular(8),
                )
              ],
            );
          }),
          // ... rest of your chart code remains the same
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, meta) {
                  const style = TextStyle(fontSize: 11, color: Color(0xFF8D99AE), fontWeight: FontWeight.w500);
                  final index = v.toInt();
                  if (index >= 0 && index < labels.length) {
                    String label = labels[index];
                    if (label.length > 8) {
                      label = label.split(' ').first;
                    }
                    return Text(label, style: style);
                  }
                  return const Text("");
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: maxValue > 20 ? 10 : 5,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF8D99AE), fontWeight: FontWeight.w500),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            horizontalInterval: maxValue > 20 ? 10 : 5,
            getDrawingHorizontalLine: (v) => FlLine(
              color: const Color(0xFFE5E7EB).withOpacity(0.5),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (BarChartGroupData group) => const Color(0xFF1F2937),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final deptName = groupIndex < labels.length ? labels[groupIndex] : 'Department';
                return BarTooltipItem(
                  "$deptName\n${rod.toY.toInt()} issues",
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                );
              },
            ),
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('❌ Chart Error: $e');
      print('📋 Stack trace: $stackTrace');
      return _buildErrorState(e);
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 48, color: Color(0xFF687280)),
          SizedBox(height: 8),
          Text(
            "No data available",
            style: TextStyle(color: Color(0xFF687280)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
          const SizedBox(height: 8),
          Text(
            "Error loading chart",
            style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ---------------- Resolution Trend Chart (Fixed) ----------------
class _ResolutionTrendChart extends StatelessWidget {
  final List<dynamic> resolutionTrends;
  const _ResolutionTrendChart({required this.resolutionTrends});

  @override
  Widget build(BuildContext context) {
    if (resolutionTrends.isEmpty) {
      return const Center(
        child: Text(
          "No trend data available",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final colors = [
      const Color(0xFF4361EE),
      const Color(0xFF4CC9F0),
      const Color(0xFF7209B7),
      const Color(0xFFF72585),
    ];

    return Column(
      children: [
        // Legend Row
        SizedBox(
          height: 32,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: resolutionTrends.length,
            itemBuilder: (context, index) {
              final trend = resolutionTrends[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      trend['department'],
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF2B2D42),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Chart
        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withOpacity(0.1),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final trend = resolutionTrends.isNotEmpty ? resolutionTrends[0] : null;
                      final months = trend != null ? List<String>.from(trend['months']) : [];
                      final index = value.toInt();
                      if (index >= 0 && index < months.length) {
                        return Text(
                          months[index],
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF8D99AE),
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }
                      return const Text("");
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        "${value.toInt()}%",
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF8D99AE),
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              lineBarsData: resolutionTrends.asMap().entries.map((entry) {
                final index = entry.key;
                final trend = entry.value;
                
                // FIX: Convert data to double safely
                final rawData = trend['data'] as List;
                final trendData = rawData.map((x) {
                  if (x is int) return x.toDouble();
                  if (x is double) return x;
                  if (x is num) return x.toDouble();
                  if (x is String) return double.tryParse(x) ?? 0.0;
                  return 0.0;
                }).toList();
                
                return LineChartBarData(
                  spots: trendData.asMap().entries.map((dataEntry) {
                    return FlSpot(dataEntry.key.toDouble(), dataEntry.value);
                  }).toList(),
                  isCurved: true,
                  color: colors[index % colors.length],
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                );
              }).toList(),
              minY: 50,
              maxY: 100,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------- Department Detail Page (Enhanced) ----------------
class DepartmentDetailPage extends StatefulWidget {
  final int deptId;
  final String name;
  final IconData icon;
  final int resolved;
  final int pending;
  final int progress;
  final double efficiency;
  final int totalIssues;

  const DepartmentDetailPage({
    super.key,
    required this.deptId,
    required this.name,
    required this.icon,
    required this.resolved,
    required this.pending,
    required this.progress,
    required this.efficiency,
    required this.totalIssues,
  });

  @override
  State<DepartmentDetailPage> createState() => _DepartmentDetailPageState();
}

class _DepartmentDetailPageState extends State<DepartmentDetailPage> {
  late int resolved;
  late int pending;
  late int progress;
  late double efficiency;
  late int totalIssues;
  List<double> efficiencyTrend = [];
  bool isLoading = true;

  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    resolved = widget.resolved;
    pending = widget.pending;
    progress = widget.progress;
    efficiency = widget.efficiency;
    totalIssues = widget.totalIssues;
    _loadEfficiencyTrend();
  }

  Future<void> _loadEfficiencyTrend() async {
    try {
      final response = await apiService.getDepartmentEfficiencyTrend(widget.deptId);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rawTrend = data['efficiency_trend'] as List;
        
        setState(() {
          // FIX: Convert to double safely
          efficiencyTrend = rawTrend.map((x) {
            if (x is int) return x.toDouble();
            if (x is double) return x;
            if (x is num) return x.toDouble();
            if (x is String) return double.tryParse(x) ?? 0.0;
            return 0.0;
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading efficiency trend: $e');
      setState(() {
        efficiencyTrend = [];
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedPct = totalIssues == 0 ? 0.0 : (resolved / totalIssues) * 100;
    final pendingPct = totalIssues == 0 ? 0.0 : (pending / totalIssues) * 100;
    final progressPct = totalIssues == 0 ? 0.0 : (progress / totalIssues) * 100;

    const primaryColor = Color(0xFF4361EE);
    const backgroundColor = Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(widget.name),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2B2D42),
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF2B2D42)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4361EE), Color(0xFF3A0CA3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, size: 30, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Total issues: $totalIssues • Efficiency: ${efficiency.toStringAsFixed(1)}%",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () => _showFeedbackDialog(widget.name),
                    icon: const Icon(Icons.feedback_outlined, size: 18),
                    label: const Text("Feedback"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Stats Cards - FIX: Removed nested Expanded
            Row(
              children: [
                _buildModernStatCard("Resolved", resolved, resolvedPct, const Color(0xFF4ADE80)),
                const SizedBox(width: 12),
                _buildModernStatCard("Pending", pending, pendingPct, const Color(0xFFF59E0B)),
                const SizedBox(width: 12),
                _buildModernStatCard("In Progress", progress, progressPct, const Color(0xFF3B82F6)),
              ],
            ),

            const SizedBox(height: 24),

            // Efficiency Trend Chart
            Container(
              decoration: _modernDetailCardDecoration(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Efficiency Trend",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF2B2D42),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Last 6 months performance",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : efficiencyTrend.isEmpty
                            ? const Center(child: Text("No trend data available"))
                            : LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawHorizontalLine: true,
                                    getDrawingHorizontalLine: (value) => FlLine(
                                      color: Colors.grey.withOpacity(0.1),
                                      strokeWidth: 1,
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 30,
                                        getTitlesWidget: (value, meta) {
                                          final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"];
                                          final index = value.toInt();
                                          if (index >= 0 && index < months.length && index < efficiencyTrend.length) {
                                            return Text(
                                              months[index],
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF8D99AE),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            );
                                          }
                                          return const Text("");
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 36,
                                        getTitlesWidget: (value, meta) {
                                          return Text(
                                            "${value.toInt()}%",
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF8D99AE),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                                  ),
                                  minY: 50,
                                  maxY: 100,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: efficiencyTrend.asMap().entries.map((entry) {
                                        return FlSpot(entry.key.toDouble(), entry.value);
                                      }).toList(),
                                      isCurved: true,
                                      color: primaryColor,
                                      barWidth: 4,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(
                                        show: true,
                                        getDotPainter: (spot, percent, barData, index) {
                                          return FlDotCirclePainter(
                                            radius: 4,
                                            color: primaryColor,
                                            strokeWidth: 2,
                                            strokeColor: Colors.white,
                                          );
                                        },
                                      ),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          colors: [
                                            primaryColor.withOpacity(0.3),
                                            primaryColor.withOpacity(0.1),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Breakdown Section
            Container(
              decoration: _modernDetailCardDecoration(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Breakdown",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF2B2D42),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: Row(
                      children: [
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              centerSpaceRadius: 40,
                              sectionsSpace: 4,
                              sections: _detailPieSections(),
                              pieTouchData: PieTouchData(enabled: true),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildDetailLegend(const Color(0xFF4ADE80), "Resolved", resolved, resolvedPct),
                              const SizedBox(height: 12),
                              _buildDetailLegend(const Color(0xFFF59E0B), "Pending", pending, pendingPct),
                              const SizedBox(height: 12),
                              _buildDetailLegend(const Color(0xFF3B82F6), "In Progress", progress, progressPct),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildModernStatCard(String title, int value, double pct, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF8D99AE),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              color: color,
              backgroundColor: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              minHeight: 6,
            ),
            const SizedBox(height: 8),
            Text(
              "${pct.toStringAsFixed(0)}%",
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8D99AE),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _detailPieSections() {
    return [
      PieChartSectionData(
        value: resolved.toDouble(),
        color: const Color(0xFF4ADE80),
        radius: 40,
        title: "$resolved",
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      PieChartSectionData(
        value: pending.toDouble(),
        color: const Color(0xFFF59E0B),
        radius: 40,
        title: "$pending",
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      PieChartSectionData(
        value: progress.toDouble(),
        color: const Color(0xFF3B82F6),
        radius: 40,
        title: "$progress",
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    ];
  }

  Widget _buildDetailLegend(Color color, String label, int value, double pct) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2B2D42),
            ),
          ),
        ),
        Text(
          "$value (${pct.toStringAsFixed(0)}%)",
          style: const TextStyle(
            color: Color(0xFF8D99AE),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  BoxDecoration _modernDetailCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  void _showFeedbackDialog(String deptName) {
    TextEditingController feedbackController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Feedback for $deptName"),
        content: TextField(
          controller: feedbackController,
          decoration: InputDecoration(
            hintText: "Enter feedback or remarks...",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4361EE)),
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Color(0xFF8D99AE))),
          ),
          ElevatedButton(
            onPressed: () async {
              if (feedbackController.text.trim().isNotEmpty) {
                try {
                  await apiService.submitDepartmentFeedback(
                    widget.deptId,
                    feedbackController.text.trim(),
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Feedback submitted for $deptName"),
                      backgroundColor: const Color(0xFF4CC9F0),
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Failed to submit feedback: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4361EE),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }
}