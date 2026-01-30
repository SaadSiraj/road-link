import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:roadlink/core/utils/size_utils.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/routes/routes_name.dart';
import '../../../core/shared/app_button.dart';
import '../../../core/shared/app_text.dart';
import '../../../services/auth_service.dart';

class PrivacyPermissionsView extends StatefulWidget {
  const PrivacyPermissionsView({super.key});

  @override
  State<PrivacyPermissionsView> createState() => _PrivacyPermissionsViewState();
}

class _PrivacyPermissionsViewState extends State<PrivacyPermissionsView> {
  final AuthService _authService = AuthService();
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(
              Icons.privacy_tip_outlined,
              color: AppColors.textPrimary,
              size: 24.fSize,
            ),
            SizedBox(width: 12.h),
            AppText(
              'Privacy & Permissions',
              size: 20.fSize,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.h, vertical: 24.v),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Privacy Settings Section
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16.adaptSize),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.adaptSize),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40.adaptSize,
                            height: 40.adaptSize,
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.lock_outline,
                              color: AppColors.primaryBlue,
                              size: 20.fSize,
                            ),
                          ),
                          Gap.h(12),
                          Expanded(
                            child: AppText(
                              'Privacy Settings',
                              size: 15.fSize,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Gap.v(16),
                      Divider(color: AppColors.border, height: 1),
                      Gap.v(16),

                      _buildPrivacyItem(
                        icon: Icons.visibility_outlined,
                        title: 'Profile Visibility',
                        subtitle: 'Control who can see your profile',
                        onTap: () {
                          // TODO: Implement profile visibility settings
                        },
                      ),
                      Gap.v(16),
                      _buildPrivacyItem(
                        icon: Icons.location_on_outlined,
                        title: 'Location Sharing',
                        subtitle: 'Manage location permissions',
                        onTap: () {
                          // TODO: Implement location sharing settings
                        },
                      ),
                      Gap.v(16),
                      _buildPrivacyItem(
                        icon: Icons.notifications_outlined,
                        title: 'Notification Preferences',
                        subtitle: 'Control how you receive notifications',
                        onTap: () {
                          // TODO: Implement notification preferences
                        },
                      ),
                    ],
                  ),
                ),
              ),

              Gap.v(24),

              /// Permissions Section
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16.adaptSize),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.adaptSize),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40.adaptSize,
                            height: 40.adaptSize,
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.security_outlined,
                              color: AppColors.primaryBlue,
                              size: 20.fSize,
                            ),
                          ),
                          Gap.h(12),
                          Expanded(
                            child: AppText(
                              'App Permissions',
                              size: 15.fSize,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Gap.v(16),
                      Divider(color: AppColors.border, height: 1),
                      Gap.v(16),

                      _buildPrivacyItem(
                        icon: Icons.camera_alt_outlined,
                        title: 'Camera',
                        subtitle: 'Access to take photos',
                        onTap: () {
                          // TODO: Implement camera permission settings
                        },
                      ),
                      Gap.v(16),
                      _buildPrivacyItem(
                        icon: Icons.photo_library_outlined,
                        title: 'Photo Library',
                        subtitle: 'Access to select photos',
                        onTap: () {
                          // TODO: Implement photo library permission settings
                        },
                      ),
                      Gap.v(16),
                      _buildPrivacyItem(
                        icon: Icons.location_on_outlined,
                        title: 'Location',
                        subtitle: 'Access to your location',
                        onTap: () {
                          // TODO: Implement location permission settings
                        },
                      ),
                    ],
                  ),
                ),
              ),

              Gap.v(24),

              /// Delete Account Button
              CustomButton(
                text: _isDeleting ? 'Deleting...' : 'Delete Account',
                onPressed: _isDeleting ? () {} : _showDeleteAccountDialog,
                backgroundColor: AppColors.error,
                textColor: AppColors.white,
                icon: Icons.delete_outline,
                borderRadius: 12.adaptSize,
                height: 50.v,
                isDisabled: _isDeleting,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteAccountDialog() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 24.fSize,
            ),
            Gap.h(12),
            Expanded(
              child: AppText(
                'Delete Account',
                size: 20.fSize,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              'Are you sure you want to delete your account?',
              size: 15.fSize,
              color: AppColors.textPrimary,
            ),
            Gap.v(12),
            AppText(
              'This action cannot be undone. All your data including:',
              size: 13.fSize,
              color: AppColors.textSecondary,
            ),
            Gap.v(8),
            Padding(
              padding: EdgeInsets.only(left: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    '• Your profile information',
                    size: 13.fSize,
                    color: AppColors.textSecondary,
                  ),
                  AppText(
                    '• All registered cars',
                    size: 13.fSize,
                    color: AppColors.textSecondary,
                  ),
                  AppText(
                    '• All associated data',
                    size: 13.fSize,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            Gap.v(12),
            AppText(
              'will be permanently deleted.',
              size: 13.fSize,
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: AppText(
              'Cancel',
              size: 15.fSize,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: AppText(
              'Delete',
              size: 15.fSize,
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showSnackBar('User is not signed in', isError: true);
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await _authService.deleteAccount(currentUser.uid);
      
      if (!mounted) return;

      _showSnackBar('Account deleted successfully', isError: false);
      
      // Navigate to auth selection screen after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        AppRouter.pushAndRemoveUntil(
          context,
          RouteNames.authSelection,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        'Failed to delete account. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AppText(
          message,
          color: AppColors.white,
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }

  Widget _buildPrivacyItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.v),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? AppColors.error : AppColors.textSecondary,
              size: 20.fSize,
            ),
            Gap.h(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    title,
                    size: 15.fSize,
                    fontWeight: FontWeight.w600,
                    color: isDestructive ? AppColors.error : AppColors.textPrimary,
                  ),
                  Gap.v(4),
                  AppText(
                    subtitle,
                    size: 13.fSize,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20.fSize,
            ),
          ],
        ),
      ),
    );
  }
}

