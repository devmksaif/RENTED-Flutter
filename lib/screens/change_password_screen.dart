import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';
import '../models/api_error.dart';
import '../utils/responsive_utils.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.updateProfile(
        currentPassword: _currentPasswordController.text,
        password: _newPasswordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Password changed successfully',
          backgroundColor: Colors.green,
        );
        Navigator.pop(context);
      }
    } on ApiError catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: e.message,
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to change password: ${e.toString()}',
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = ResponsiveUtils(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Change Password',
          style: TextStyle(fontSize: responsive.fontSize(20)),
        ),
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: responsive.responsivePadding(mobile: 16, tablet: 24, desktop: 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(responsive.spacing(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Update your password',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.textTheme.titleLarge?.color,
                              fontSize: responsive.fontSize(18),
                            ),
                          ),
                          SizedBox(height: responsive.spacing(8)),
                          Text(
                            'Enter your current password and choose a new one',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.hintColor,
                              fontSize: responsive.fontSize(14),
                            ),
                          ),
                          SizedBox(height: responsive.spacing(24)),
                        // Current Password
                        TextFormField(
                          controller: _currentPasswordController,
                          obscureText: _obscureCurrentPassword,
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: responsive.fontSize(14),
                          ),
                          decoration: InputDecoration(
                            labelText: 'Current Password',
                            labelStyle: TextStyle(fontSize: responsive.fontSize(14)),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: AppTheme.primaryGreen,
                              size: responsive.iconSize(24),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureCurrentPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: theme.hintColor,
                                size: responsive.iconSize(24),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureCurrentPassword = !_obscureCurrentPassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: theme.inputDecorationTheme.fillColor,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your current password';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: responsive.spacing(16)),
                        // New Password
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: _obscureNewPassword,
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: responsive.fontSize(14),
                          ),
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            labelStyle: TextStyle(fontSize: responsive.fontSize(14)),
                            prefixIcon: Icon(
                              Icons.lock,
                              color: AppTheme.primaryGreen,
                              size: responsive.iconSize(24),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureNewPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: theme.hintColor,
                                size: responsive.iconSize(24),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureNewPassword = !_obscureNewPassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: theme.inputDecorationTheme.fillColor,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a new password';
                            }
                            if (value.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: responsive.spacing(16)),
                        // Confirm Password
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: responsive.fontSize(14),
                          ),
                          decoration: InputDecoration(
                            labelText: 'Confirm New Password',
                            labelStyle: TextStyle(fontSize: responsive.fontSize(14)),
                            prefixIcon: Icon(
                              Icons.lock,
                              color: AppTheme.primaryGreen,
                              size: responsive.iconSize(24),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: theme.hintColor,
                                size: responsive.iconSize(24),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: theme.inputDecorationTheme.fillColor,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your new password';
                            }
                            if (value != _newPasswordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: responsive.spacing(24)),
                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _changePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: responsive.spacing(16)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: responsive.iconSize(20),
                                    width: responsive.iconSize(20),
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Change Password',
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(16),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ], // End of inner Column children (Padding > Column)
                    ), // End of inner Column
                  ), // End of Padding
                ), // End of Container
                ], // End of outer Column children (Form > Column)
              ), // End of Column
            ), // End of Form
          ), // End of ConstrainedBox
        ), // End of SingleChildScrollView
      ), // End of SafeArea
    ); // End of Scaffold
  }
}

