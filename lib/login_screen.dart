import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'services/auth_service.dart';
import 'services/session_manager.dart';
import 'services/social_auth_service.dart';
import 'models/api_error.dart';
import 'config/app_theme.dart';
import 'utils/responsive_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final SessionManager _sessionManager = SessionManager();
  final SocialAuthService _socialAuthService = SocialAuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _performLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authResponse = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Update session manager with user data
      await _sessionManager.updateSession(authResponse.user);

      if (mounted) {
        Fluttertoast.showToast(
          msg: "Login successful! Welcome back.",
          backgroundColor: AppTheme.successGreen,
        );
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(msg: e.message, backgroundColor: AppTheme.errorRed);
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
          // Login form
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
                        "Welcome Back!",
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
                            height: responsive.responsive(mobile: 200, tablet: 300, desktop: 350),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: responsive.responsive(mobile: responsive.screenWidth * 0.9, tablet: 500, desktop: 600),
                              height: responsive.responsive(mobile: 200, tablet: 300, desktop: 350),
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
                    SizedBox(height: responsive.spacing(40)),
                      // Sign in button
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
                        child: SizedBox(
                          width: responsive.responsive(mobile: responsive.screenWidth * 0.8, tablet: 400, desktop: 500),
                          height: responsive.responsive(mobile: 50, tablet: 55, desktop: 60),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _performLogin,
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
                              : Text(
                                  "Sign In",
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(18),
                                    color: Colors.white,
                                  ),
                                ),
                          ),
                        ),
                      ),
                      SizedBox(height: responsive.spacing(15)),
                      // Forgot password link
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, "/forgot-password"),
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: responsive.fontSize(14),
                          ),
                        ),
                      ),
                      SizedBox(height: responsive.spacing(10)),
                      // Register link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: theme.hintColor,
                              fontSize: responsive.fontSize(14),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, "/register"),
                            child: Text(
                              "Create one",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                                fontSize: responsive.fontSize(14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: responsive.spacing(20)),
                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: theme.dividerColor)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: responsive.spacing(16)),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: theme.hintColor,
                                fontSize: responsive.fontSize(14),
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: theme.dividerColor)),
                        ],
                      ),
                      SizedBox(height: responsive.spacing(20)),
                      // Google Sign In Button - COMMENTED OUT FOR NOW
                      // SizedBox(
                      //   width: responsive.responsive(mobile: responsive.screenWidth * 0.8, tablet: 400, desktop: 500),
                      //   height: responsive.responsive(mobile: 50, tablet: 55, desktop: 60),
                      //   child: OutlinedButton.icon(
                      //     onPressed: _isLoadingGoogle ? null : _signInWithGoogle,
                      //     style: OutlinedButton.styleFrom(
                      //       side: BorderSide(color: theme.dividerColor),
                      //       shape: RoundedRectangleBorder(
                      //         borderRadius: BorderRadius.circular(12),
                      //       ),
                      //     ),
                      //     icon: _isLoadingGoogle
                      //         ? const SizedBox(
                      //             width: 20,
                      //             height: 20,
                      //             child: CircularProgressIndicator(strokeWidth: 2),
                      //           )
                      //         : Image.asset(
                      //             'assets/images/google_logo.png',
                      //             width: 20,
                      //             height: 20,
                      //             errorBuilder: (_, __, ___) => const Icon(
                      //               Icons.g_mobiledata,
                      //               size: 24,
                      //             ),
                      //           ),
                      //     label: Text(
                      //       'Sign in with Google',
                      //       style: TextStyle(fontSize: responsive.fontSize(16)),
                      //     ),
                      //   ),
                      // ),
                      // SizedBox(height: responsive.spacing(20)),
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

  // Google Sign-In method commented out along with the button
  // Future<void> _signInWithGoogle() async {
  //   if (!mounted) return;
  //   
  //   setState(() {
  //     _isLoadingGoogle = true;
  //   });
  //
  //   try {
  //     // Sign in with Google using Firebase Auth
  //     final authResponse = await _socialAuthService.signInWithGoogle();
  //
  //     if (!mounted) return;
  //
  //     // Update session manager with user data
  //     await _sessionManager.updateSession(authResponse.user);
  //
  //     if (mounted) {
  //       try {
  //         Fluttertoast.showToast(
  //           msg: 'Login successful! Welcome ${authResponse.user.name}',
  //           backgroundColor: AppTheme.successGreen,
  //         );
  //       } catch (e) {
  //         // Ignore toast errors
  //         print('Toast error: $e');
  //       }
  //       
  //       // Small delay to ensure token is saved
  //       await Future.delayed(const Duration(milliseconds: 100));
  //       
  //       if (mounted) {
  //         Navigator.pushReplacementNamed(context, '/home');
  //       }
  //     }
  //   } on ApiError catch (e) {
  //     if (mounted) {
  //       try {
  //         Fluttertoast.showToast(
  //           msg: e.message,
  //           backgroundColor: AppTheme.errorRed,
  //           toastLength: Toast.LENGTH_LONG,
  //         );
  //       } catch (toastError) {
  //         // If toast fails, show a dialog instead
  //         if (mounted) {
  //           showDialog(
  //             context: context,
  //             builder: (context) => AlertDialog(
  //               title: const Text('Sign-In Error'),
  //               content: Text(e.message),
  //               actions: [
  //                 TextButton(
  //                   onPressed: () => Navigator.pop(context),
  //                   child: const Text('OK'),
  //                 ),
  //               ],
  //             ),
  //           );
  //         }
  //       }
  //     }
  //   } catch (e, stackTrace) {
  //     // Log the full error for debugging
  //     print('Google Sign-In Error: $e');
  //     print('Stack trace: $stackTrace');
  //     
  //     if (mounted) {
  //       final errorMessage = e.toString().length > 100 
  //           ? 'Failed to sign in with Google. Please try again.'
  //           : 'Failed to sign in with Google: ${e.toString()}';
  //       
  //       try {
  //         Fluttertoast.showToast(
  //           msg: errorMessage,
  //           backgroundColor: AppTheme.errorRed,
  //           toastLength: Toast.LENGTH_LONG,
  //         );
  //       } catch (toastError) {
  //         // If toast fails, show a dialog instead
  //         if (mounted) {
  //           showDialog(
  //             context: context,
  //             builder: (context) => AlertDialog(
  //               title: const Text('Sign-In Error'),
  //               content: Text(errorMessage),
  //               actions: [
  //                 TextButton(
  //                   onPressed: () => Navigator.pop(context),
  //                   child: const Text('OK'),
  //                 ),
  //               ],
  //             ),
  //           );
  //         }
  //       }
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         _isLoadingGoogle = false;
  //       });
  //     }
  //   }
  // }
}
