import 'package:flutter/material.dart';
import '/services/auth_service.dart'; // Add this import

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
  final TextEditingController confirmPasswordController =
      TextEditingController();

  String selectedRole = 'Citizen';
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isLoading = false; // Add loading state

  @override
  void initState() {
    super.initState();

    // Animation for pop-up effect
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _scaleAnimation =
        Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.forward(); // Start animation
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void toggleTab(bool loginSelected) {
    setState(() {
      isLogin = loginSelected;
    });
    _controller.forward(from: 0.0);
  }

  // Add this method for API call
  Future<void> _handleAuth() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isLogin ? "Signing in..." : "Creating account..."))
      );

      final AuthService authService = AuthService();
      final Map<String, dynamic> result;

      try {
        if (isLogin) {
          result = await authService.login(
            emailController.text.trim(),
            passwordController.text,
          );
        } else {
          result = await authService.register(
            emailController.text.trim(),
            passwordController.text,
            selectedRole,
          );
        }

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isLogin ? "Login successful!" : "Account created!"),
              backgroundColor: Colors.green,
            )
          );
          // Navigate to dashboard after successful auth
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: ${result['error']}"),
              backgroundColor: Colors.red,
            )
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Network error: $e"),
            backgroundColor: Colors.red,
          )
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const tealColor = Color(0xFF006D5B); // darker teal

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 380,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.apartment, size: 60, color: tealColor),
                  const SizedBox(height: 8),
                  const Text(
                    "CIVIC EYE",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: tealColor),
                  ),
                  const Text(
                    "AI-powered smart civic issue management",
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 30),

                  // Toggle Tabs (Rounded with Hover)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTabButton("Sign In", true, tealColor),
                      const SizedBox(width: 20),
                      _buildTabButton("Sign Up", false, tealColor),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // Title
                  Text(
                    isLogin ? "Welcome Back" : "Create Account",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isLogin
                        ? "Sign in to access the civic issue management system"
                        : "Join the smart civic issue management system",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 25),

                  // Form Fields
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: "Email",
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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

                        if (!isLogin) ...[
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: confirmPasswordController,
                            decoration: InputDecoration(
                              labelText: "Confirm Password",
                              prefixIcon:
                                  const Icon(Icons.lock_person_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please confirm your password";
                              }
                              if (value != passwordController.text) {
                                return "Passwords do not match";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          DropdownButtonFormField<String>(
                            value: selectedRole,
                            decoration: InputDecoration(
                              labelText: "Role",
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Citizen', child: Text('Citizen')),
                              DropdownMenuItem(
                                  value: 'Admin', child: Text('Admin')),
                            ],
                            onChanged: (value) {
                              setState(() => selectedRole = value!);
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please select a role";
                              }
                              return null;
                            },
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Submit Button - UPDATED WITH API CALL
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: tealColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: tealColor.withOpacity(0.4),
                    ),
                    onPressed: _isLoading ? null : _handleAuth, // Disable when loading
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
                                fontSize: 18, color: Colors.white, letterSpacing: 1),
                          ),
                  ),

                  // Add forgot password link for login
                  if (isLogin) ...[
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: _isLoading ? null : () {
                        // TODO: Implement forgot password
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Forgot password feature coming soon!"))
                        );
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, bool loginTab, Color tealColor) {
    final bool isActive = loginTab == isLogin;

    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: GestureDetector(
        onTap: _isLoading ? null : () => toggleTab(loginTab), // Disable when loading
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding:
              const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? tealColor : Colors.grey[200],
            borderRadius: BorderRadius.circular(25),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: tealColor.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}