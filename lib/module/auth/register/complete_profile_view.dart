import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:roadlink/core/utils/size_utils.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/shared/app_button.dart';
import '../../../core/shared/app_text.dart';
import '../../../core/shared/app_textfield.dart';
import '../../../core/shared/loading_dialogue.dart';
import '../../../viewmodels/auth_viewmodel.dart';

class CompleteProfileView extends StatelessWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  const CompleteProfileView({super.key, this.onNext, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.h, vertical: 24.v),
            child: CompleteProfileContent(
              onNext: onNext,
              onBack: onBack ?? () => Navigator.pop(context),
            ),
          ),
        ),
      ),
    );
  }
}

class CompleteProfileContent extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  const CompleteProfileContent({super.key, this.onNext, this.onBack});

  @override
  State<CompleteProfileContent> createState() => _CompleteProfileContentState();
}

class _CompleteProfileContentState extends State<CompleteProfileContent> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _fullNameController = TextEditingController();

  Future<bool> _ensureImagePermission(ImageSource source) async {
    // On iOS, image_picker handles permission prompts automatically.
    // On Android, request explicit runtime permissions.
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera permission is required to take a photo.'),
            ),
          );
        }
        return false;
      }
    } else {
      // Gallery / photos
      var status = await Permission.photos.request();
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo library permission is required to choose a photo.'),
            ),
          );
        }
        return false;
      }
    }
    return true;
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.adaptSize)),
      ),
      builder:
          (context) => Padding(
            padding: EdgeInsets.all(20.adaptSize),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  'Choose Profile Photo',
                  size: 18.fSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                Gap.v(20),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8.adaptSize),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.adaptSize),
                    ),
                    child: Icon(Icons.camera_alt, color: AppColors.primaryBlue),
                  ),
                  title: AppText(
                    'Take Photo',
                    size: 16.fSize,
                    color: AppColors.textPrimary,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                Gap.v(8),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8.adaptSize),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.adaptSize),
                    ),
                    child: Icon(
                      Icons.photo_library,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  title: AppText(
                    'Choose from Gallery',
                    size: 16.fSize,
                    color: AppColors.textPrimary,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_selectedImage != null) ...[
                  Gap.v(8),
                  ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(8.adaptSize),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.adaptSize),
                      ),
                      child: const Icon(Icons.delete, color: Colors.red),
                    ),
                    title: AppText(
                      'Remove Photo',
                      size: 16.fSize,
                      color: AppColors.textPrimary,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                  ),
                ],
                Gap.v(10),
              ],
            ),
          ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!await _ensureImagePermission(source)) return;
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleComplete(AuthViewModel auth) {
    if (auth.isLoading) return;
    final fullName = _fullNameController.text.trim();
    if (fullName.isEmpty) {
      _showSnack('Please enter your full name.');
      return;
    }

    LoadingDialog.show(context, message: 'Completing profile');
    auth.completeProfile(
      fullName: fullName,
      profileImage: _selectedImage,
      onSuccess: () {
        if (!context.mounted) return;
        LoadingDialog.hide(context);
        widget.onNext?.call();
      },
      onError: (error) {
        if (!context.mounted) return;
        LoadingDialog.hide(context);
        _showSnack(error);
      },
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    return Column(
      children: [
        /// 🔹 CARD
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(24.adaptSize),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: EdgeInsets.all(24.adaptSize),
          child: Column(
            children: [
              /// Icon
              Container(
                height: 72.adaptSize,
                width: 72.adaptSize,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: AppColors.primaryBlue,
                  size: 32.adaptSize,
                ),
              ),

              Gap.v(24),

              /// Title
              AppText(
                'Complete Profile',
                size: 28.fSize,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),

              Gap.v(12),

              /// Subtitle
              AppText(
                'Add your details to personalize your experience.',
                size: 15.fSize,
                align: TextAlign.center,
                color: AppColors.textSecondary,
              ),

              Gap.v(32),

              /// Profile Photo Upload
              Column(
                children: [
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Stack(
                      children: [
                        Container(
                          height: 120.adaptSize,
                          width: 120.adaptSize,
                          decoration: BoxDecoration(
                            color: AppColors.textFieldFillColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  _selectedImage != null
                                      ? AppColors.primaryBlue
                                      : AppColors.border,
                              width: 2,
                            ),
                            image:
                                _selectedImage != null
                                    ? DecorationImage(
                                      image: FileImage(_selectedImage!),
                                      fit: BoxFit.cover,
                                    )
                                    : null,
                          ),
                          child:
                              _selectedImage == null
                                  ? Icon(
                                    Icons.person_rounded,
                                    size: 60.adaptSize,
                                    color: AppColors.textSecondary.withOpacity(
                                      0.5,
                                    ),
                                  )
                                  : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(10.adaptSize),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.cardBackground,
                                width: 3,
                              ),
                            ),
                            child: Icon(
                              _selectedImage == null
                                  ? Icons.add_a_photo_rounded
                                  : Icons.edit_rounded,
                              color: Colors.white,
                              size: 18.adaptSize,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Gap.v(16),

                  TextButton(
                    onPressed: _showImageSourceDialog,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.h,
                        vertical: 12.v,
                      ),
                      backgroundColor: AppColors.textFieldFillColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.adaptSize),
                        side: BorderSide(
                          color: AppColors.border.withOpacity(0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _selectedImage == null
                              ? Icons.camera_alt_outlined
                              : Icons.edit_outlined,
                          size: 20.fSize,
                          color: AppColors.white,
                        ),
                        Gap.h(8),
                        AppText(
                          _selectedImage == null
                              ? 'Upload Profile Photo'
                              : 'Change Profile Photo',
                          size: 14.fSize,
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              Gap.v(32),
              const Divider(color: AppColors.border, thickness: 1),
              Gap.v(24),

              /// Full Name Section
              ReusableTextField(
                controller: _fullNameController,
                label: 'Full Name',
                hintText: 'Enter your full name',
                keyboardType: TextInputType.name,
                borderRadius: 12.adaptSize,
                fillColor: AppColors.textFieldFillColor,
                textColor: AppColors.textPrimary,
              ),

              if (auth.errorMessage != null) ...[
                Gap.v(16),
                AppText(
                  auth.errorMessage!,
                  size: 12.fSize,
                  color: AppColors.error,
                ),
              ],

              Gap.v(32),

              /// Complete Setup Button
              CustomButton(
                text: auth.isLoading ? 'Completing...' : 'Complete Setup',
                onPressed: () => _handleComplete(auth),
                backgroundColor: AppColors.primaryBlue,
                textColor: AppColors.white,
                borderRadius: 12.adaptSize,
                height: 52.v,
                width: double.infinity,
                fontSize: 16.fSize,
                fontWeight: FontWeight.bold,
                isDisabled: auth.isLoading,
              ),

              Gap.v(14),

              /// Back Button
              CustomButton(
                text: 'Back',
                onPressed: widget.onBack ?? () {},
                backgroundColor: Colors.transparent,
                textColor: AppColors.textSecondary,
                borderRadius: 12.adaptSize,
                height: 48.v,
                width: double.infinity,
                fontSize: 15.fSize,
                fontWeight: FontWeight.w500,
                borderColor: AppColors.border,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
