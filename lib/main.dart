// lib/main.dart

import 'package:flutter/material.dart';
import 'screens/dashboard/correcteddashboard.dart';

void main() {
  runApp(const CivicEyeApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Urban Issue Redressal',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DashboardScreen(), 
    );
  }
}
