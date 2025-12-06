import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../services/settings_service.dart';
import '../services/auth_service.dart';
import '../models/api_error.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final AuthService _authService = AuthService();
  bool _pushNotifications = true;
  bool _isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _settingsService.getAllSettings();
      if (mounted) {
        setState(() {
          _pushNotifications = settings['pushNotifications'] ?? true;
        });
      }
    } catch (e) {
      // Settings load failed, using defaults
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: responsive.responsivePadding(mobile: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notifications Section
              _buildSectionTitle('Notifications'),
              SizedBox(height: responsive.spacing(12)),
              _buildSettingsCard([
                _buildSwitchTile(
                  'Push Notifications',
                  'Receive push notifications',
                  _pushNotifications,
                  (value) async {
                    setState(() => _pushNotifications = value);
                    await _settingsService.setPushNotifications(value);
                    Fluttertoast.showToast(
                      msg: 'Push notifications ${value ? "enabled" : "disabled"}',
                      backgroundColor: Colors.green,
                    );
                  },
                ),
              ]),
              SizedBox(height: responsive.spacing(24)),

              // Appearance Section
              _buildSectionTitle('Appearance'),
              SizedBox(height: responsive.spacing(12)),
              _buildSettingsCard([
                _buildSwitchTile(
                  'Dark Mode',
                  'Use dark theme',
                  themeProvider.isDarkMode,
                  (value) async {
                    await themeProvider.setDarkMode(value);
                    Fluttertoast.showToast(
                      msg: value ? 'Dark mode enabled' : 'Light mode enabled',
                      backgroundColor: AppTheme.primaryGreen,
                    );
                  },
                ),
              ]),
              SizedBox(height: responsive.spacing(24)),

              // Account Section
              _buildSectionTitle('Account'),
              SizedBox(height: responsive.spacing(12)),
              _buildSettingsCard([
                _buildActionTile('Change Password', Icons.lock, () {
                  Navigator.pushNamed(context, '/change-password');
                }),
                const Divider(height: 1),
                _buildActionTile('Privacy Settings', Icons.privacy_tip, () {
                  _showPrivacySettings();
                }),
                const Divider(height: 1),
                _buildActionTile(
                  'Delete Account',
                  Icons.delete_forever,
                  () => _showDeleteAccountDialog(),
                  textColor: Colors.red,
                  iconColor: Colors.red,
                ),
              ]),
              SizedBox(height: responsive.spacing(24)),

              // Legal Section
              _buildSectionTitle('Legal'),
              SizedBox(height: responsive.spacing(12)),
              _buildSettingsCard([
                _buildActionTile('Terms of Service', Icons.description, () {
                  _showTermsOfService();
                }),
                const Divider(height: 1),
                _buildActionTile('Privacy Policy', Icons.policy, () {
                  _showPrivacyPolicy();
                }),
              ]),
              SizedBox(height: responsive.spacing(24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: theme.textTheme.titleLarge?.color,
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    final theme = Theme.of(context);
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppTheme.primaryGreen,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }


  Widget _buildActionTile(
    String title,
    IconData icon,
    VoidCallback onTap, {
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppTheme.primaryGreen),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: textColor,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showDeleteAccountDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          'Delete Account',
          style: TextStyle(color: theme.textTheme.titleLarge?.color),
        ),
        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone. All your data will be permanently deleted.',
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
        ),
        actions: [
          TextButton(
            onPressed: _isDeletingAccount
                ? null
                : () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.hintColor),
            ),
          ),
          ElevatedButton(
            onPressed: _isDeletingAccount
                ? null
                : () async {
                    Navigator.pop(context);
                    await _deleteAccount();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: _isDeletingAccount
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    setState(() {
      _isDeletingAccount = true;
    });

    try {
      await _authService.deleteAccount();

      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Account deleted successfully',
          backgroundColor: AppTheme.successGreen,
        );

        // Navigate to login screen after successful deletion
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } on ApiError catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: e.message,
          backgroundColor: AppTheme.errorRed,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to delete account: ${e.toString()}',
          backgroundColor: AppTheme.errorRed,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingAccount = false;
        });
      }
    }
  }

  void _showPrivacySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Settings'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Privacy Options',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('• Profile Visibility: Public'),
              Text('• Show Email: Hidden'),
              Text('• Show Phone: Hidden'),
              Text('• Allow Messages: Enabled'),
              SizedBox(height: 12),
              Text(
                'These settings control how others can see and contact you.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'TERMS OF SERVICE\n\n'
            'Last updated: December 2025\n\n'
            '1. ACCEPTANCE OF TERMS\n'
            'By accessing and using RENTED, you accept and agree to be bound by these Terms of Service.\n\n'
            '2. USER ACCOUNTS\n'
            'You are responsible for maintaining the confidentiality of your account and password.\n\n'
            '3. RENTAL AGREEMENTS\n'
            'All rentals are subject to our rental terms and conditions.\n\n'
            '4. PROHIBITED ACTIVITIES\n'
            'You may not use the service for any illegal or unauthorized purpose.\n\n'
            '5. LIMITATION OF LIABILITY\n'
            'RENTED is not liable for any damages arising from the use of our service.\n\n'
            'For the complete terms, please visit our website.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'PRIVACY POLICY\n\n'
            'Last updated: December 2025\n\n'
            '1. INFORMATION WE COLLECT\n'
            'We collect information you provide directly to us, including name, email, and payment information.\n\n'
            '2. HOW WE USE YOUR INFORMATION\n'
            'We use your information to provide, maintain, and improve our services.\n\n'
            '3. INFORMATION SHARING\n'
            'We do not sell your personal information to third parties.\n\n'
            '4. DATA SECURITY\n'
            'We implement appropriate security measures to protect your data.\n\n'
            '5. YOUR RIGHTS\n'
            'You have the right to access, update, or delete your personal information.\n\n'
            'For the complete privacy policy, please visit our website.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
