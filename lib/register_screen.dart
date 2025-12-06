import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'services/auth_service.dart';
import 'services/session_manager.dart';
import 'models/api_error.dart';
import 'config/app_theme.dart';
import 'utils/responsive_utils.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  final SessionManager _sessionManager = SessionManager();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _performRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authResponse = await _authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      // Update session manager with user data
      await _sessionManager.updateSession(authResponse.user);

      if (mounted) {
        Fluttertoast.showToast(
          msg: "Registration successful! Welcome to RENTED.",
          backgroundColor: Colors.green,
        );
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(msg: e.message, backgroundColor: Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = ResponsiveUtils(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Top left splash
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: responsive.responsive(mobile: 200, tablet: 250, desktop: 300),
              height: responsive.responsive(mobile: 200, tablet: 250, desktop: 300),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(150),
              ),
            ),
          ),
          // Bottom right splash
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: responsive.responsive(mobile: 250, tablet: 300, desktop: 350),
              height: responsive.responsive(mobile: 250, tablet: 300, desktop: 350),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(200),
              ),
            ),
          ),
          // Register form
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: responsive.responsivePadding(mobile: 20, tablet: 40, desktop: 60),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Heading
                      Text(
                        "Create Account",
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkGreen,
                              fontSize: responsive.fontSize(24),
                            ),
                      ),
                      SizedBox(height: responsive.spacing(20)),
                      // Image
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withValues(
                                alpha: 0.2,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/login_vec.jpg',
                            width: responsive.responsive(mobile: responsive.screenWidth * 0.9, tablet: 500, desktop: 600),
                            height: responsive.responsive(mobile: 200, tablet: 250, desktop: 300),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: responsive.responsive(mobile: responsive.screenWidth * 0.9, tablet: 500, desktop: 600),
                              height: responsive.responsive(mobile: 200, tablet: 250, desktop: 300),
                              color: theme.cardColor,
                              child: Icon(
                                Icons.image,
                                size: responsive.iconSize(64),
                                color: theme.hintColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: responsive.spacing(30)),
                      // Name field
                      SizedBox(
                        width: 400,
                        child: TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: "Full Name",
                            prefixIcon: Icon(
                              Icons.person_outlined,
                              color: theme.hintColor,
                            ),
                            filled: true,
                            fillColor: theme.inputDecorationTheme.fillColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Name is required';
                            }
                            if (value.length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: responsive.spacing(20)),
                      // Email field
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
                        child: SizedBox(
                          width: responsive.responsive(mobile: responsive.screenWidth * 0.9, tablet: 500, desktop: 600),
                          child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: "Email",
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: theme.hintColor,
                            ),
                            filled: true,
                            fillColor: theme.inputDecorationTheme.fillColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email is required';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.spacing(20)),
                    // Password field
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
                        child: SizedBox(
                          width: responsive.responsive(mobile: responsive.screenWidth * 0.9, tablet: 500, desktop: 600),
                          child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: "Password",
                            prefixIcon: Icon(
                              Icons.lock_outlined,
                              color: theme.hintColor,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: theme.hintColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: theme.inputDecorationTheme.fillColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.spacing(20)),
                    // Confirm Password field
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
                        child: SizedBox(
                          width: responsive.responsive(mobile: responsive.screenWidth * 0.9, tablet: 500, desktop: 600),
                          child: TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            style: TextStyle(fontSize: responsive.fontSize(14)),
                            decoration: InputDecoration(
                              hintText: "Confirm Password",
                              prefixIcon: Icon(
                                Icons.lock_outlined,
                                color: theme.hintColor,
                                size: responsive.iconSize(24),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: theme.hintColor,
                                  size: responsive.iconSize(24),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: theme.inputDecorationTheme.fillColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: responsive.spacing(40)),
                      // Register button
                      SizedBox(
                        width: responsive.responsive(mobile: responsive.screenWidth * 0.8, tablet: 400, desktop: 500),
                        height: responsive.responsive(mobile: 50, tablet: 55, desktop: 60),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _performRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  "Create Account",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: TextStyle(color: theme.hintColor),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, "/login"),
                            child: const Text(
                              "Sign In",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
