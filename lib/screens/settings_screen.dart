import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../config/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  bool _pushNotifications = true;
  bool _darkMode = false;
  String _language = 'English';
  String _currency = 'USD';

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
          _darkMode = settings['darkMode'] ?? false;
          _language = settings['language'] ?? 'English';
          _currency = settings['currency'] ?? 'USD';
        });
      }
    } catch (e) {
      // Settings load failed, using defaults
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
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
                _buildSwitchTile('Dark Mode', 'Use dark theme', _darkMode, (
                  value,
                ) async {
                  setState(() => _darkMode = value);
                  await _settingsService.setDarkMode(value);
                  Fluttertoast.showToast(
                    msg: 'Dark mode saved (theme refresh coming soon)',
                    backgroundColor: Colors.blue,
                  );
                }),
              ]),
              SizedBox(height: responsive.spacing(24)),

              // Preferences Section
              _buildSectionTitle('Preferences'),
              SizedBox(height: responsive.spacing(12)),
              _buildSettingsCard([
                _buildDropdownTile(
                  'Language',
                  _language,
                  ['English', 'Spanish', 'French', 'German'],
                  (value) async {
                    setState(() => _language = value!);
                    await _settingsService.setLanguage(value!);
                    Fluttertoast.showToast(
                      msg: 'Language saved: $value',
                      backgroundColor: Colors.green,
                    );
                  },
                ),
                const Divider(height: 1),
                _buildDropdownTile(
                  'Currency',
                  _currency,
                  ['USD', 'EUR', 'GBP', 'JPY'],
                  (value) async {
                    setState(() => _currency = value!);
                    await _settingsService.setCurrency(value!);
                    Fluttertoast.showToast(
                      msg: 'Currency saved: $value',
                      backgroundColor: Colors.green,
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
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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

  Widget _buildDropdownTile(
    String title,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        underline: const SizedBox(),
        items: items.map((item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
      ),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Implement account deletion API call
              Fluttertoast.showToast(
                msg: 'Account deletion feature will be available soon',
                backgroundColor: Colors.orange,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
