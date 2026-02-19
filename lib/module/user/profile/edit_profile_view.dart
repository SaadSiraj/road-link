import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:roadlink/core/utils/size_utils.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/shared/app_button.dart';
import '../../../core/shared/app_text.dart';
import '../../../core/shared/app_textfield.dart';
import '../../../services/auth_service.dart';

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
  String? _photoUrl;
  bool _isLoading = false;
  bool _isUpdating = false;
  bool _isUploadingPhoto = false;

  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();

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
      final storedPhotoUrl = (data['photoUrl'] as String?)?.trim();
      if (mounted) {
        setState(() {
          _photoUrl = (storedPhotoUrl != null && storedPhotoUrl.isNotEmpty)
              ? storedPhotoUrl
              : FirebaseAuth.instance.currentUser?.photoURL;
        });
      }
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

  Future<void> _pickAndUpdatePhoto() async {
    final uid = _uid;
    if (uid == null || _isUploadingPhoto) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.adaptSize)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.v, horizontal: 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppText(
                'Update profile photo',
                size: 16.fSize,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              Gap.v(16),
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColors.primaryBlue),
                title: AppText('Take photo', size: 15.fSize, color: AppColors.textPrimary),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.primaryBlue),
                title: AppText('Choose from gallery', size: 15.fSize, color: AppColors.textPrimary),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              Gap.v(8),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final xFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (xFile == null || !mounted) return;

      File? file = File(xFile.path);
      final cropped = await ImageCropper().cropImage(
        sourcePath: file.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop photo',
            toolbarColor: AppColors.scaffoldBackground,
            toolbarWidgetColor: AppColors.textPrimary,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop photo',
            aspectRatioLockEnabled: true,
          ),
        ],
      );
      if (cropped != null) file = File(cropped.path);
      if (!mounted) return;

      setState(() => _isUploadingPhoto = true);

      final url = await _authService.uploadProfilePhoto(file: file, uid: uid);
      if (url == null || url.isEmpty || !mounted) {
        setState(() => _isUploadingPhoto = false);
        _showSnackBar('Failed to upload photo', isError: true);
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'photoUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await currentUser.updatePhotoURL(url);
      }

      if (!mounted) return;
      setState(() {
        _photoUrl = url;
        _isUploadingPhoto = false;
      });
      _showSnackBar('Profile photo updated', isError: false);
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        _showSnackBar('Failed to update photo. Please try again.', isError: true);
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
                    /// Profile photo – tap to update
                    Center(
                      child: GestureDetector(
                        onTap: _pickAndUpdatePhoto,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 100.adaptSize,
                              height: 100.adaptSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primaryBlue,
                                  width: 3,
                                ),
                              ),
                              child: ClipOval(
                                child: _isUploadingPhoto
                                    ? Container(
                                        color: AppColors.textFieldFillColor,
                                        child: Center(
                                          child: SizedBox(
                                            width: 32.adaptSize,
                                            height: 32.adaptSize,
                                            child: CircularProgressIndicator(
                                              color: AppColors.primaryBlue,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                      )
                                    : _photoUrl != null && _photoUrl!.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: _photoUrl!,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => Container(
                                              color: AppColors.textFieldFillColor,
                                              child: Center(
                                                child: CircularProgressIndicator(
                                                  color: AppColors.primaryBlue,
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            ),
                                            errorWidget: (_, __, ___) => _buildPlaceholderAvatar(),
                                          )
                                        : _buildPlaceholderAvatar(),
                              ),
                            ),
                            if (!_isUploadingPhoto)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 32.adaptSize,
                                  height: 32.adaptSize,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.scaffoldBackground,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 16.fSize,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Gap.v(24),

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

  Widget _buildPlaceholderAvatar() {
    return Container(
      color: AppColors.textFieldFillColor,
      child: Icon(
        Icons.person,
        size: 50.fSize,
        color: AppColors.textSecondary,
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

