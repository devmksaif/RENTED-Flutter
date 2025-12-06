import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/user.dart';
import '../models/api_error.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';
import '../mixins/refresh_on_focus_mixin.dart';
import '../utils/responsive_utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver, RefreshOnFocusMixin {
  final AuthService _authService = AuthService();
  final SessionManager _sessionManager = SessionManager();
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  Future<void> onRefresh() async {
    // Refresh user profile when screen comes into focus
    await _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (e.statusCode == 401) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _authService.logout();
        // Clear session manager
        await _sessionManager.clearSession();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        // Even if API logout fails, clear session locally
        await _sessionManager.clearSession();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/edit-profile');
              // Reload user data if profile was updated
              if (result == true && mounted) {
                _loadUser();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
          ? const Center(child: Text('Unable to load profile'))
          : _buildProfileContent(theme),
    );
  }

  Widget _buildProfileContent(ThemeData theme) {
    final responsive = ResponsiveUtils(context);
    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile Header
          Container(
            width: double.infinity,
            padding: responsive.responsivePadding(mobile: 24, tablet: 32, desktop: 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: responsive.responsive(mobile: 50, tablet: 60, desktop: 70),
                  backgroundColor: theme.cardColor,
                  backgroundImage: _user!.avatarUrl != null && _user!.avatarUrl!.isNotEmpty
                      ? NetworkImage(_user!.avatarUrl!)
                      : null,
                  child: _user!.avatarUrl == null || _user!.avatarUrl!.isEmpty
                      ? Text(
                    _user!.name[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: responsive.fontSize(36),
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                        )
                      : null,
                ),
                SizedBox(height: responsive.spacing(16)),
                Text(
                  _user!.name,
                  style: TextStyle(
                    fontSize: responsive.fontSize(24),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: responsive.spacing(8)),
                Text(
                  _user!.email,
                  style: TextStyle(
                    fontSize: responsive.fontSize(16), 
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: responsive.spacing(12)),
                _buildVerificationBadge(),
              ],
            ),
          ),

          // Menu Items
          _buildMenuItem(
            icon: Icons.inventory_2,
            title: 'My Products',
            onTap: () => Navigator.pushNamed(context, '/my-products'),
          ),
          _buildMenuItem(
            icon: Icons.receipt_long,
            title: 'My Rentals',
            onTap: () => Navigator.pushNamed(context, '/my-rentals'),
          ),
          _buildMenuItem(
            icon: Icons.shopping_bag,
            title: 'My Purchases',
            onTap: () => Navigator.pushNamed(context, '/my-purchases'),
          ),
          _buildMenuItem(
            icon: Icons.favorite,
            title: 'Favorites',
            onTap: () => Navigator.pushNamed(context, '/favorites'),
          ),
          _buildMenuItem(
            icon: Icons.reviews,
            title: 'My Reviews',
            onTap: () => Navigator.pushNamed(context, '/my-reviews'),
          ),
          _buildMenuItem(
            icon: Icons.chat_bubble_outline,
            title: 'Messages',
            onTap: () => Navigator.pushNamed(context, '/conversations'),
          ),
          _buildMenuItem(
            icon: Icons.gavel,
            title: 'Disputes',
            onTap: () => Navigator.pushNamed(context, '/disputes'),
          ),
          const Divider(),
          _buildMenuItem(
            icon: Icons.verified_user,
            title: 'Verification Status',
            onTap: () async {
              final result = await Navigator.pushNamed(
                context,
                '/verification',
              );
              // Reload user data if verification status changed
              if (result == true && mounted) {
                _loadUser();
              }
            },
            trailing: _user!.isVerified
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.pending, color: Colors.orange),
          ),
          _buildMenuItem(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () => Navigator.pushNamed(context, '/help'),
          ),
          const Divider(),
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: _logout,
            textColor: AppTheme.errorRed,
            iconColor: AppTheme.errorRed,
          ),
          SizedBox(height: responsive.spacing(24)),
        ],
      ),
    );
  }

  Widget _buildVerificationBadge() {
    final theme = Theme.of(context);
    final responsive = ResponsiveUtils(context);
    if (_user!.isVerified) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.spacing(16),
          vertical: responsive.spacing(8),
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified, color: AppTheme.successGreen, size: responsive.iconSize(18)),
            SizedBox(width: responsive.spacing(6)),
            Text(
              'Verified',
              style: TextStyle(
                color: AppTheme.successGreen,
                fontWeight: FontWeight.bold,
                fontSize: responsive.fontSize(14),
              ),
            ),
          ],
        ),
      );
    } else if (_user!.isPending) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.spacing(16),
          vertical: responsive.spacing(8),
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pending, color: AppTheme.warningOrange, size: responsive.iconSize(18)),
            SizedBox(width: responsive.spacing(6)),
            Text(
              'Pending Verification',
              style: TextStyle(
                color: AppTheme.warningOrange,
                fontWeight: FontWeight.bold,
                fontSize: responsive.fontSize(14),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.spacing(16),
          vertical: responsive.spacing(8),
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning, color: AppTheme.errorRed, size: responsive.iconSize(18)),
            SizedBox(width: responsive.spacing(6)),
            Text(
              'Not Verified',
              style: TextStyle(
                color: AppTheme.errorRed, 
                fontWeight: FontWeight.bold,
                fontSize: responsive.fontSize(14),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
    Color? textColor,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    final responsive = ResponsiveUtils(context);
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? theme.textTheme.bodyLarge?.color,
        size: responsive.iconSize(24),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? theme.textTheme.bodyLarge?.color,
          fontWeight: FontWeight.w500,
          fontSize: responsive.fontSize(16),
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right,
            color: theme.hintColor,
          ),
      onTap: onTap,
    );
  }
}
