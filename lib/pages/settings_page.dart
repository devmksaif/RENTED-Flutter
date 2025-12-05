import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  bool emailNotifications = true;
  bool pushNotifications = true;
  bool darkMode = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Account Section
            _SectionTitle('Account'),
            _SettingsTile(
              title: 'Edit Profile',
              icon: Icons.edit,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Edit profile coming soon')),
                );
              },
            ),
            _SettingsTile(
              title: 'Change Password',
              icon: Icons.lock,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Change password coming soon')),
                );
              },
            ),
            Divider(),

            // Notifications Section
            _SectionTitle('Notifications'),
            _SwitchTile(
              title: 'All Notifications',
              value: notificationsEnabled,
              onChanged: (value) {
                setState(() => notificationsEnabled = value);
              },
            ),
            _SwitchTile(
              title: 'Email Notifications',
              value: emailNotifications,
              onChanged: (value) {
                setState(() => emailNotifications = value);
              },
            ),
            _SwitchTile(
              title: 'Push Notifications',
              value: pushNotifications,
              onChanged: (value) {
                setState(() => pushNotifications = value);
              },
            ),
            Divider(),

            // Display Section
            _SectionTitle('Display'),
            _SwitchTile(
              title: 'Dark Mode',
              value: darkMode,
              onChanged: (value) {
                setState(() => darkMode = value);
              },
            ),
            Divider(),

            // Help & Support Section
            _SectionTitle('Help & Support'),
            _SettingsTile(
              title: 'About RENTED',
              icon: Icons.info,
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'RENTED',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2025 RENTED. All rights reserved.',
                );
              },
            ),
            _SettingsTile(
              title: 'Terms of Service',
              icon: Icons.description,
              onTap: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Terms of Service')));
              },
            ),
            _SettingsTile(
              title: 'Privacy Policy',
              icon: Icons.privacy_tip,
              onTap: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Privacy Policy')));
              },
            ),
            _SettingsTile(
              title: 'Contact Support',
              icon: Icons.help,
              onTap: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('support@rented.com')));
              },
            ),
            Divider(),

            // Logout Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorRed,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Logout coming soon')),
                    );
                  },
                  child: Text(
                    'Logout',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryGreen,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryGreen),
      title: Text(title, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
      trailing: Icon(Icons.arrow_forward, color: theme.hintColor, size: 18),
      onTap: onTap,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(title, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryGreen,
      ),
    );
  }
}
