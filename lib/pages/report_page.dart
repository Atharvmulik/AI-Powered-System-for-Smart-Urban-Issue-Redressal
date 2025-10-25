import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../screens/dashboard/correcteddashboard.dart';
import '../screens/admin/admin_dashboard.dart';

class LoginSignupPage extends StatefulWidget {
  const LoginSignupPage({super.key});

  @override
  State<LoginSignupPage> createState() => _LoginSignupPageState();
}

class _LoginSignupPageState extends State<LoginSignupPage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  bool isLogin = true;
  bool isLoading = false;
  
  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => isLoading = true);

  try {
    Map<String, dynamic> result;
    
    if (isLogin) {
      result = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } else {
      result = await _authService.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _fullNameController.text.trim(),
        _mobileController.text.trim(),
      );
    }

    setState(() => isLoading = false);

    if (result['success']) {
      final bool isAdmin = result['is_admin'] ?? false;
      
      // Navigate based on user type
      if (isAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardScreen(
              userEmail: _emailController.text.trim(), // Use email from form
              userName: _fullNameController.text.trim().isNotEmpty 
                  ? _fullNameController.text.trim() 
                  : 'User', // Use name from form or default
            ),
          ),
        );
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isLogin ? 'Login successful!' : 'Registration successful!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error']),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('An error occurred: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                
                // Logo and Title
                Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.radio_button_checked,
                        size: 60,
                        color: Colors.teal,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'CivicEye',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                        ),
                      ),
                      Text(
                        isLogin ? 'Welcome Back!' : 'Create Account',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),

                // Full Name Field (only for registration)
                if (!isLogin) ...[
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Mobile Field (only for registration)
                if (!isLogin) ...[
                  TextFormField(
                    controller: _mobileController,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your mobile number';
                      }
                      if (value.length < 10) {
                        return 'Please enter a valid mobile number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(isLogin ? 'Login' : 'Sign Up'),
                  ),
                ),
                const SizedBox(height: 20),

                // Switch between Login/Signup
                Center(
                  child: TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            setState(() => isLogin = !isLogin);
                          },
                    child: Text(
                      isLogin
                          ? "Don't have an account? Sign Up"
                          : "Already have an account? Login",
                      style: const TextStyle(color: Colors.teal),
                    ),
                  ),
                ),

                // Admin Info
                const SizedBox(height: 20),
                const Center(
                  child: Column(
                    children: [
                      Text(
                        'Admin Access:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Use admin1@civiceye.com to admin4@civiceye.com\nor vaishnavi@civiceye.com to access admin dashboard',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Admin accounts cannot be registered',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}