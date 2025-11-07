import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../screens/dashboard/correcteddashboard.dart';
import '../../screens/admin/admin_dashboard.dart';

class LoginSignupPage extends StatefulWidget {
  const LoginSignupPage({super.key});

  @override
  State<LoginSignupPage> createState() => _LoginSignupPageState();
}

class _LoginSignupPageState extends State<LoginSignupPage>
    with SingleTickerProviderStateMixin {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isLoading = false;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void toggleTab(bool loginSelected) {
    setState(() {
      isLogin = loginSelected;
    });
    _controller.forward(from: 0.0);
  }

  Future<void> _handleAuth() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isLogin ? "Signing in..." : "Creating account..."))
      );

      try {
        Map<String, dynamic> result;
        
        if (isLogin) {
          print('🔐 Attempting LOGIN with: ${emailController.text.trim()}');
          result = await _authService.login(
            emailController.text.trim(),
            passwordController.text.trim(),
          );
        } else {
          print('🔐 Attempting REGISTER with: ${emailController.text.trim()}');
          result = await _authService.register(
            emailController.text.trim(),
            passwordController.text.trim(),
            nameController.text.trim(),
            phoneController.text.trim(),
          );
        }

        setState(() {
          _isLoading = false;
        });

        // 🔍 EXTENSIVE DEBUGGING
        print('🎯 FULL RESULT OBJECT:');
        print('   - Entire result: $result');
        print('   - Success: ${result['success']}');
        print('   - is_admin: ${result['is_admin']}');
        print('   - Error: ${result['error']}');
        print('   - Email: ${result['email']}');
        print('   - User Name: ${result['user_name']}');

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isLogin ? "Login successful!" : "Account created!"),
              backgroundColor: Colors.green,
            )
          );
          
          // Get user data from result
          final String userEmail = result['email'] ?? emailController.text.trim();
          final String userName = result['user_name'] ?? 
              (isLogin ? 'User' : nameController.text.trim());
          
          // 🔍 CRITICAL: FIX ADMIN DETECTION
          final bool isAdmin = _authService.isAdminEmail(userEmail);
          
          // 🔍 DEBUG ADMIN DETECTION
          print('🎯 ADMIN DETECTION DEBUG:');
          print('   - User Email: $userEmail');
          print('   - Is Admin Email: $isAdmin');
          print('   - Admin Emails List: ${AuthService.adminUsers}'); // ✅ FIXED: Use static access
          
          // Navigate based on user type
          if (isAdmin) {
            print('🚀 ADMIN DETECTED - REDIRECTING TO ADMIN DASHBOARD');
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => AdminDashboardPage(
                  userEmail: userEmail,
                  userName: userName,
                ),
              ),
              (route) => false,
            );
          } else {
            print('🚀 USER DETECTED - REDIRECTING TO USER DASHBOARD');
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardScreen(
                  userEmail: userEmail,
                  userName: userName,
                ),
              ),
              (route) => false,
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: ${result['error']}"),
              backgroundColor: Colors.red,
            )
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        print('❌ EXCEPTION: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Network error: $e"),
            backgroundColor: Colors.red,
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color.fromRGBO(67, 97, 238, 1);
    const secondaryColor = Color.fromRGBO(67, 97, 238, 0.1);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: SingleChildScrollView(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 420,
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: secondaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.apartment, size: 50, color: primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "UrbanSim AI",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "AI-powered smart civic issue management",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Toggle Tabs
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _buildTabButton("Sign In", true, primaryColor),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTabButton("Sign Up", false, primaryColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Main Content Card with Hover Effects
                  MouseRegion(
                    onEnter: (_) => _controller.forward(),
                    onExit: (_) => _controller.reverse(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: primaryColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: FadeTransition(
                        opacity: _opacityAnimation,
                        child: Column(
                          children: [
                            // Title Section
                            Text(
                              isLogin ? "Welcome Back" : "Create Account",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isLogin
                                  ? "Sign in to access the civic issue management system"
                                  : "Join the smart civic issue management system",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Form Fields
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Name Field (only for signup)
                                  if (!isLogin) ...[
                                    _buildFormField(
                                      controller: nameController,
                                      label: "Full Name",
                                      icon: Icons.person_outline,
                                      validator: (value) {
                                        if (!isLogin && (value == null || value.isEmpty)) {
                                          return "Please enter your full name";
                                        }
                                        if (!isLogin && value!.length < 2) {
                                          return "Name must be at least 2 characters";
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // Phone Field (only for signup)
                                    _buildFormField(
                                      controller: phoneController,
                                      label: "Phone Number",
                                      icon: Icons.phone_outlined,
                                      keyboardType: TextInputType.phone,
                                      validator: (value) {
                                        if (!isLogin && (value == null || value.isEmpty)) {
                                          return "Please enter your phone number";
                                        }
                                        if (!isLogin && !RegExp(r'^\d{10}$').hasMatch(value!)) {
                                          return "Phone must be 10 digits";
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  // Email Field
                                  _buildFormField(
                                    controller: emailController,
                                    label: "Email",
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Please enter your email";
                                      }
                                      if (!value.contains('@')) {
                                        return "Please enter a valid email";
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Password Field
                                  _buildFormField(
                                    controller: passwordController,
                                    label: "Password",
                                    icon: Icons.lock_outline,
                                    obscureText: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Please enter your password";
                                      }
                                      if (value.length < 6) {
                                        return "Password must be at least 6 characters";
                                      }
                                      return null;
                                    },
                                  ),

                                  // Confirm Password (only for signup)
                                  if (!isLogin) ...[
                                    const SizedBox(height: 16),
                                    _buildFormField(
                                      controller: confirmPasswordController,
                                      label: "Confirm Password",
                                      icon: Icons.lock_person_outlined,
                                      obscureText: true,
                                      validator: (value) {
                                        if (!isLogin && (value == null || value.isEmpty)) {
                                          return "Please confirm your password";
                                        }
                                        if (!isLogin && value != passwordController.text) {
                                          return "Passwords do not match";
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Submit Button
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 56),
                                    backgroundColor: primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 4,
                                    shadowColor: primaryColor.withOpacity(0.4),
                                  ),
                                  onPressed: _isLoading ? null : _handleAuth,
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Text(
                                          isLogin ? "Sign In" : "Create Account",
                                          style: const TextStyle(
                                            fontSize: 16, 
                                            color: Colors.white, 
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                ),
                              ),
                            ),

                            // Forgot Password Link
                            if (isLogin) ...[
                              const SizedBox(height: 16),
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: TextButton(
                                  onPressed: _isLoading ? null : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Forgot password feature coming soon!"))
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: primaryColor,
                                  ),
                                  child: const Text(
                                    "Forgot Password?",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, bool loginTab, Color primaryColor) {
    final bool isActive = loginTab == isLogin;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _isLoading ? null : () => toggleTab(loginTab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey[600],
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.text,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: const Color.fromRGBO(67, 97, 238, 0.7)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color.fromRGBO(67, 97, 238, 1), width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}