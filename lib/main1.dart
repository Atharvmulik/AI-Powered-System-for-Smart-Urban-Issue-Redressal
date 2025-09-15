// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/test_connection.dart'; // Import the test screen

void main() {
  runApp(MyApp());
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
      home: TestConnectionScreen(), // Temporarily use test screen
    );
  }
}