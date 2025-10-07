// lib/main.dart - Enhanced version with navigation

import 'package:flutter/material.dart';
import 'pages/report_page.dart';
import 'screens/dashboard/correcteddashboard.dart';

void main() {
  runApp(const CivicEyeApp());
}

class CivicEyeApp extends StatelessWidget {
  const CivicEyeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CivicEye - Urban Issue Redressal',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: const DashboardScreen(),
      routes: {
        '/report': (context) => ReportPage(),
        '/dashboard': (context) => const DashboardScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

// Optional: If you want to add a bottom navigation bar
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    ReportPage(), // You can add more screens here
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem),
            label: 'Report Issue',
          ),
        ],
      ),
    );
  }
}