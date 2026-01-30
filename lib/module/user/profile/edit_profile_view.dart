import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:roadlink/core/utils/size_utils.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/shared/app_button.dart';
import '../../../core/shared/app_text.dart';
import '../../../core/shared/app_textfield.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  String? _uid;
  bool _isLoading = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    _uid = currentUser?.uid;
    _seedFromAuth(currentUser);
    _loadFromFirestore();
  }

  void _seedFromAuth(User? user) {
    final displayName = user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      _fullNameController.text = displayName;
    }
  }

  Future<void> _loadFromFirestore() async {
    final uid = _uid;
    if (uid == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (!mounted || data == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      _fullNameController.text = (data['name'] as String?) ?? '';
      _phoneController.text = (data['phone'] as String?) ?? '';
      _bioController.text = (data['bio'] as String?) ?? '';
    } catch (_) {
      // Ignore for now (screen can still render with fallbacks).
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    final uid = _uid;
    if (uid == null) return;

    final fullName = _fullNameController.text.trim();
    final bio = _bioController.text.trim();

    if (fullName.isEmpty) {
      _showSnackBar('Please enter your full name', isError: true);
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      // Update Firestore
      final doc = FirebaseFirestore.instance.collection('users').doc(uid);
      await doc.set({
        'name': fullName,
        'bio': bio,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update Firebase Auth display name
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await currentUser.updateDisplayName(fullName);
        // Note: Email update requires re-authentication, so we only update Firestore
      }

      if (!mounted) return;

      _showSnackBar('Profile updated successfully', isError: false);
      
      // Navigate back after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Failed to update profile. Please try again.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
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

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

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
              Icons.person_outline,
              color: AppColors.textPrimary,
              size: 24.fSize,
            ),
            SizedBox(width: 12.h),
            AppText(
              'Edit Profile',
              size: 20.fSize,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryBlue,
                ),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.h, vertical: 24.v),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Personal Information Section
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
                                    Icons.person_outline,
                                    color: AppColors.primaryBlue,
                                    size: 20.fSize,
                                  ),
                                ),
                                Gap.h(12),
                                Expanded(
                                  child: AppText(
                                    'Personal Information',
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

                            _simpleLabel('Full Name'),
                            Gap.v(8),
                            ReusableTextField(
                              controller: _fullNameController,
                              hintText: 'John Doe',
                              borderRadius: 10.adaptSize,
                              fillColor: AppColors.textFieldFillColor,
                              textColor: AppColors.textPrimary,
                              showClearButton: true,
                            ),
                            Gap.v(16),

                            _simpleLabel('Phone'),
                            Gap.v(8),
                            ReusableTextField(
                              controller: _phoneController,
                              hintText: '0123 456 789',
                              keyboardType: TextInputType.phone,
                              readOnly: true,
                              borderRadius: 10.adaptSize,
                              fillColor: AppColors.textFieldFillColor,
                              textColor: AppColors.textPrimary,
                              showClearButton: false,
                            ),
                            Gap.v(16),

                            _simpleLabel('Bio'),
                            Gap.v(8),
                            ReusableTextField(
                              controller: _bioController,
                              hintText: 'Car enthusiast. Always up for a drive or a car meet!',
                              maxLines: 3,
                              borderRadius: 10.adaptSize,
                              fillColor: AppColors.textFieldFillColor,
                              textColor: AppColors.textPrimary,
                              showClearButton: true,
                            ),
                          ],
                        ),
                      ),
                    ),

                    Gap.v(24),

                    /// Update Button
                    CustomButton(
                      text: _isUpdating ? 'Updating...' : 'Update',
                      onPressed: _isUpdating ? () {} : _updateProfile,
                      backgroundColor: AppColors.primaryBlue,
                      textColor: AppColors.white,
                 
                      borderRadius: 12.adaptSize,
                      height: 50.v,
                      isDisabled: _isUpdating,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _simpleLabel(String title) {
    return AppText(
      title,
      size: 13.fSize,
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w600,
    );
  }
}

