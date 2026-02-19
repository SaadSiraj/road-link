import 'dart:developer' as developer;

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
    developer.log('🔴 Showing logout dialog', name: 'AdminDrawer');
    
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
            onPressed: () {
              developer.log('🔴 User cancelled logout', name: 'AdminDrawer');
              Navigator.of(dialogContext).pop(false);
            },
            child: AppText(
              'Cancel',
              size: 15.fSize,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextButton(
            onPressed: () async {
              developer.log('🔴 User confirmed logout', name: 'AdminDrawer');
              // Close dialog first
              Navigator.of(dialogContext).pop(true);
            },
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

    developer.log('🔴 Dialog closed, shouldLogout: $shouldLogout', name: 'AdminDrawer');

    if (shouldLogout == true && mounted) {
      developer.log('🔴 Logout confirmed and widget mounted, proceeding with logout', name: 'AdminDrawer');
      await _performLogout();
    } else if (shouldLogout == true && !mounted) {
      developer.log('🔴 Logout confirmed but widget NOT mounted', name: 'AdminDrawer');
    } else {
      developer.log('🔴 Logout cancelled', name: 'AdminDrawer');
    }
  }

  Future<void> _performLogout() async {
    developer.log('🔴 _performLogout() started', name: 'AdminDrawer');
    
    if (!mounted) {
      developer.log('🔴 ERROR: Widget not mounted in _performLogout()', name: 'AdminDrawer');
      return;
    }
    
    setState(() {
      _isLoggingOut = true;
    });

    try {
      // Perform logout
      developer.log('🔴 Calling AuthService.logout()', name: 'AdminDrawer');
      await _authService.logout();
      developer.log('🔴 AuthService.logout() completed', name: 'AdminDrawer');
      
      // Use a BuildContext that's guaranteed to be valid
      // Get the navigator before any async operations
      developer.log('🔴 Getting root navigator', name: 'AdminDrawer');
      final navigator = Navigator.of(context, rootNavigator: true);
      
      developer.log('🔴 Attempting to navigate to auth selection', name: 'AdminDrawer');
      
      // Navigate to auth selection screen and clear all routes
      navigator.pushNamedAndRemoveUntil(
        RouteNames.authSelection,
        (Route<dynamic> route) {
          developer.log('🔴 Removing route: ${route.settings.name}', name: 'AdminDrawer');
          return false; // Remove all routes
        },
      );
      
      developer.log('🔴 Navigation completed successfully', name: 'AdminDrawer');
    } catch (e, stackTrace) {
      developer.log(
        '🔴 Logout error: $e',
        name: 'AdminDrawer',
        error: e,
        stackTrace: stackTrace,
      );
      
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText(
              'Failed to logout: ${e.toString()}',
              color: AppColors.white,
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
          _isLoggingOut
              ? ListTile(
                  leading: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.error),
                    ),
                  ),
                  title: const Text(
                    'Logging out...',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : _drawerItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  color: Colors.red,
                  onTap: () async {
                    developer.log('🔴 Logout button tapped in drawer', name: 'AdminDrawer');
                    // DON'T close drawer - keep it open so widget stays mounted
                    developer.log('🔴 Showing logout dialog (drawer stays open)', name: 'AdminDrawer');
                    _showLogoutDialog();
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
