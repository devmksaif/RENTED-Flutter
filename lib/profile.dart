import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    const String name = 'IyedTawila';
    const String username = '@IyedTawila';

    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Row(
                  children: [
                    Text(
                      'RENTED',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4CAF50),
                        letterSpacing: 1,
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(left: 5),
                      decoration: BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                Spacer(),
                Icon(Icons.notifications, color: Colors.grey, size: 28),
                const SizedBox(width: 16),
                // Home Icon
                IconButton(
                  icon: Icon(Icons.home),
                  color: Color(0xFF4CAF50),
                  iconSize: 28,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 32),
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Color(0xFF4CAF50),
                      child: Icon(Icons.person, size: 48, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      username,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    _buildInfoCard(
                      context,
                      title: 'Account Info',
                      icon: Icons.info_outline,
                    ),
                    const SizedBox(height: 16),
                    // Added options
                    _buildOptionCard(
                      context,
                      icon: Icons.list_alt,
                      label: 'My Listings',
                      onTap: () {},
                    ),
                    const SizedBox(height: 8),
                    _buildOptionCard(
                      context,
                      icon: Icons.settings,
                      label: 'Parameters',
                      onTap: () {},
                    ),
                    const SizedBox(height: 8),
                    _buildOptionCard(
                      context,
                      icon: Icons.book_online,
                      label: 'My Booking',
                      onTap: () {},
                    ),
                    const SizedBox(height: 16),
                    _buildOptionCard(
                      context,
                      icon: Icons.logout,
                      label: 'Logout',
                      destructive: true,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool destructive = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withAlpha(40)),
        ),
        child: Row(
          children: [
            Icon(icon, color: destructive ? Colors.red : Color(0xFF4CAF50)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: destructive ? Colors.red : Colors.black,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}

Widget _buildInfoCard(
  BuildContext context, {
  required String title,
  IconData? icon,
  String? actionLabel,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.withAlpha(40)),
    ),
    child: Row(
      children: [
        if (icon != null)
          Container(
            child: Icon(icon, color: Color(0xFF4CAF50)),
          ),
        if (icon != null) const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: () {},
            child: Text(actionLabel),
          ),
      ],
    ),
  );
}
