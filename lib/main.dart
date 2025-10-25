import 'package:flutter/material.dart';
import 'screens/auth/login_page.dart';
import 'screens/dashboard/correcteddashboard.dart';
import 'screens/admin/admin_dashboard.dart';

void main() {
  runApp(const CivicEyeApp());
}

class CivicEyeApp extends StatelessWidget {
  const CivicEyeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
      home: const LoginSignupPage(),
      routes: {
        '/login': (context) => const LoginSignupPage(),
        '/user-dashboard': (context) {
          // Get user data from arguments or use defaults
          final Map<String, String>? userData = 
              ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
          
          return DashboardScreen(
            userEmail: userData?['email'] ?? 'user@example.com',
            userName: userData?['name'] ?? 'User',
          );
        },
        '/admin-dashboard': (context) => const AdminDashboardPage(),
        '/main-navigation': (context) {
          // Get user data from arguments or use defaults
          final Map<String, String>? userData = 
              ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
          
          return MainNavigationScreen(
            userEmail: userData?['email'] ?? 'user@example.com',
            userName: userData?['name'] ?? 'User',
          );
        },
      },
    );
  }
}

// Add this ReportPage widget if you don't have it elsewhere
class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Issue'),
      ),
      body: const Center(
        child: Text(
          'Report Issue Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final String userEmail;
  final String userName;
  
  const MainNavigationScreen({
    super.key,
    required this.userEmail,
    required this.userName,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Initialize screens with user data
    _screens = [
      DashboardScreen(
        userEmail: widget.userEmail,
        userName: widget.userName,
      ),
      const ReportPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CivicEye'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
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