import 'package:flutter/material.dart';
import 'package:roadlink/core/utils/size_utils.dart';

import '../constants/app_colors.dart';
import '../routes/app_router.dart';
import '../routes/routes_name.dart';
import '../shared/app_text.dart';
import '../../services/auth_service.dart';

class AdminDrawer extends StatefulWidget {
  const AdminDrawer({super.key});

  @override
  State<AdminDrawer> createState() => _AdminDrawerState();
}

class _AdminDrawerState extends State<AdminDrawer> {
  final AuthService _authService = AuthService();
  bool _isLoggingOut = false;

  Future<void> _showLogoutDialog() async {
    if (!mounted) return;
    
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: AppText(
          'Logout',
          size: 20.fSize,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        content: AppText(
          'Are you sure you want to logout?',
          size: 15.fSize,
          color: AppColors.textSecondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: AppText(
              'Cancel',
              size: 15.fSize,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: AppText(
              'Logout',
              size: 15.fSize,
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _handleLogout();
    }
  }

  Future<void> _handleLogout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _authService.logout();
      if (!mounted) return;
      
      // Navigate to auth selection screen and clear navigation stack
      // Use Navigator directly to ensure proper navigation
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        RouteNames.authSelection,
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoggingOut = false;
      });
      // Show error message if needed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(
            'Failed to logout. Please try again.',
            color: AppColors.white,
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          /// 🔹 Drawer Header
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.scaffoldBackground, AppColors.scaffoldBackground],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 32,
                    color: AppColors.primaryBlueDark,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Admin Panel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Car System',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// 🔹 Menu Items
          _drawerItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            onTap: () {
              Navigator.pop(context);
              AppRouter.push(context, RouteNames.adminDashboard);
            },
          ),

          _drawerItem(
            icon: Icons.pending_actions,
            title: 'Pending Approvals',
            onTap: () {
              Navigator.pop(context);
              AppRouter.push(context, RouteNames.pendingCarRequests);
            },
          ),

          _drawerItem(
            icon: Icons.people,
            title: 'Users Management',
            onTap: () {
              Navigator.pop(context);
              AppRouter.push(context, RouteNames.usersManagement);
            },
          ),

          _drawerItem(
            icon: Icons.directions_car,
            title: 'Cars Management',
            onTap: () {
              Navigator.pop(context);
              AppRouter.push(context, RouteNames.carsManagement);
            },
          ),

          const Spacer(),

          const Divider(),

          /// 🔹 Logout
          _drawerItem(
            icon: Icons.logout,
            title: 'Logout',
            color: Colors.red,
            onTap: _isLoggingOut
                ? () {}
                : () async {
                    // Close drawer first
                    Navigator.pop(context);
                    // Wait a bit for drawer to close, then show dialog
                    await Future.delayed(const Duration(milliseconds: 200));
                    if (mounted) {
                      _showLogoutDialog();
                    }
                  },
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  /// 🔹 Drawer Item Widget
  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
