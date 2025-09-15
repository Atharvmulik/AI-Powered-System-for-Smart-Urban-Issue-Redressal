// lib/screens/test_connection.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/api_config.dart';

class TestConnectionScreen extends StatefulWidget {
  const TestConnectionScreen({super.key});

  @override
  _TestConnectionScreenState createState() => _TestConnectionScreenState();
}

class _TestConnectionScreenState extends State<TestConnectionScreen> {
  String _connectionStatus = 'Not tested';
  bool _isTesting = false;

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _connectionStatus = 'Testing connection...';
    });

    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/test'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _connectionStatus = 'Success: ${data['message']}';
        });
      } else {
        setState(() {
          _connectionStatus = 'Error: HTTP ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _connectionStatus = 'Error: $e';
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('API Connection Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Backend URL: ${ApiConfig.baseUrl}',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            _isTesting
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _testConnection,
                    child: Text('Test API Connection'),
                  ),
            SizedBox(height: 20),
            Text(
              _connectionStatus,
              style: TextStyle(
                fontSize: 18,
                color: _connectionStatus.contains('Error')
                    ? Colors.red
                    : Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}