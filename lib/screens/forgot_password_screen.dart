import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/password_reset_service.dart';
import '../models/api_error.dart';
import '../config/app_theme.dart';
import '../utils/responsive_utils.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final PasswordResetService _passwordResetService = PasswordResetService();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _passwordResetService.forgotPassword(
        _emailController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _emailSent = true;
        });
        Fluttertoast.showToast(
          msg: result['message'] ?? 'Password reset link sent to your email',
          backgroundColor: Colors.green,
        );
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(msg: e.message, backgroundColor: Colors.red);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(
          msg: 'An error occurred. Please try again.',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Forgot Password',
          style: TextStyle(fontSize: responsive.fontSize(20)),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: responsive.responsivePadding(mobile: 20, tablet: 40, desktop: 60),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_reset,
                    size: responsive.iconSize(80),
                    color: AppTheme.primaryGreen,
                  ),
                  SizedBox(height: responsive.spacing(20)),
                  Text(
                    _emailSent ? 'Check Your Email' : 'Forgot Password?',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: responsive.fontSize(24),
                        ),
                  ),
                  SizedBox(height: responsive.spacing(10)),
                  Text(
                    _emailSent
                        ? 'We\'ve sent a password reset link to ${_emailController.text.trim()}'
                        : 'Enter your email address and we\'ll send you a link to reset your password.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: responsive.fontSize(14),
                    ),
                  ),
                  SizedBox(height: responsive.spacing(30)),
                  if (!_emailSent) ...[
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(fontSize: responsive.fontSize(14)),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(fontSize: responsive.fontSize(14)),
                        prefixIcon: Icon(Icons.email, size: responsive.iconSize(24)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
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
                    SizedBox(height: responsive.spacing(20)),
                    SizedBox(
                      width: responsive.responsive(mobile: double.infinity, tablet: 500, desktop: 600),
                      height: responsive.responsive(mobile: 50, tablet: 55, desktop: 60),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendResetLink,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Send Reset Link',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(16),
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ] else ...[
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                      child: Text(
                        'Back to Login',
                        style: TextStyle(fontSize: responsive.fontSize(16)),
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
}

