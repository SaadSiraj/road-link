import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:roadlink/core/utils/size_utils.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/routes/routes_name.dart';
import '../../../core/shared/app_appbar.dart';
import '../../../core/shared/app_button.dart';
import '../../../core/shared/app_text.dart';
import '../../../services/auth_service.dart';
import '../dashboard/car_details_popup.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  String? _uid;
  final AuthService _authService = AuthService();
  bool _isLoggingOut = false;

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
    final email = user?.email?.trim();
    if (email != null && email.isNotEmpty) {
      _emailController.text = email;
    } else {
      _emailController.text = 'example@gmail.com';
    }
  }

  Future<void> _loadFromFirestore() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (!mounted || data == null) return;

      _fullNameController.text = (data['name'] as String?) ?? '';
      _phoneController.text = (data['phone'] as String?) ?? '';
      _bioController.text = (data['bio'] as String?) ?? '';
      
      // Use email from Firestore if available, otherwise keep from auth or fallback
      final firestoreEmail = (data['email'] as String?)?.trim();
      if (firestoreEmail != null && firestoreEmail.isNotEmpty) {
        _emailController.text = firestoreEmail;
      } else if (_emailController.text.trim().isEmpty) {
        _emailController.text = 'example@gmail.com';
      }
    } catch (_) {
      // Ignore for now (screen can still render with fallbacks).
      // Ensure email has fallback value
      if (_emailController.text.trim().isEmpty) {
        _emailController.text = 'example@gmail.com';
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _showLogoutDialog() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
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
      AppRouter.pushAndRemoveUntil(
        context,
        RouteNames.authSelection,
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
    return Scaffold(

      appBar: CustomAppBar(
        centerTitle: true,
        title: 'Profile',
        backgroundColor: AppColors.scaffoldBackground,
      ),
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.h, vertical: 24.v),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// Top bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
             
                    // Container(
                    //   width: 36.adaptSize,
                    //   height: 36.adaptSize,
                    //   decoration: BoxDecoration(
                    //     color: AppColors.cardBackground,
                    //     borderRadius: BorderRadius.circular(10.adaptSize),
                    //     border: Border.all(color: AppColors.border, width: 1),
                    //   ),
                    //   child: Icon(
                    //     Icons.settings_outlined,
                    //     color: AppColors.textPrimary,
                    //     size: 18.fSize,
                    //   ),
                    // ),
                  ],
                ),

                Gap.v(32),

                /// Avatar with edit badge
                Stack(
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
                        child: _uid != null
                            ? StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                stream: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(_uid)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  String? photoUrl;
                                  
                                  if (snapshot.hasData && snapshot.data?.data() != null) {
                                    photoUrl = snapshot.data!.data()?['photoUrl'] as String?;
                                  }
                                  
                                  // Fallback to Firebase Auth photoURL
                                  if ((photoUrl == null || photoUrl.isEmpty) && 
                                      FirebaseAuth.instance.currentUser?.photoURL != null) {
                                    photoUrl = FirebaseAuth.instance.currentUser!.photoURL;
                                  }
                                  
                                  // Use cached network image if photoUrl exists, otherwise use icon
                                  if (photoUrl != null && photoUrl.isNotEmpty) {
                                    return CachedNetworkImage(
                                      imageUrl: photoUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: AppColors.textFieldFillColor,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: AppColors.primaryBlue,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: AppColors.textFieldFillColor,
                                        child: Icon(
                                          Icons.person,
                                          size: 50.fSize,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    );
                                  } else {
                                    return Container(
                                      color: AppColors.textFieldFillColor,
                                      child: Icon(
                                        Icons.person,
                                        size: 50.fSize,
                                        color: AppColors.textSecondary,
                                      ),
                                    );
                                  }
                                },
                              )
                            : Container(
                                color: AppColors.textFieldFillColor,
                                child: Icon(
                                  Icons.person,
                                  size: 50.fSize,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                      ),
                    ),
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
                            width: 3,
                          ),
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 16.fSize,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                Gap.v(16),

                /// Name
                AppText(
                  _fullNameController.text.trim().isNotEmpty
                      ? _fullNameController.text.trim()
                      : 'John Doe',
                  size: 20.fSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),

                // Gap.v(12),

                // /// Online pill
                // Container(
                //   padding: EdgeInsets.symmetric(horizontal: 14.h, vertical: 6.v),
                //   decoration: BoxDecoration(
                //     color: AppColors.success.withOpacity(0.2),
                //     borderRadius: BorderRadius.circular(20),
                //   ),
                //   child: Row(
                //     mainAxisSize: MainAxisSize.min,
                //     children: [
                //       Container(
                //         width: 8.adaptSize,
                //         height: 8.adaptSize,
                //         decoration: const BoxDecoration(
                //           color: AppColors.success,
                //           shape: BoxShape.circle,
                //         ),
                //       ),
                //       Gap.h(6),
                //       AppText(
                //         'Online',
                //         size: 12.fSize,
                //         color: AppColors.success,
                //         fontWeight: FontWeight.w600,
                //       ),
                //     ],
                //   ),
                // ),

                Gap.v(12),

                /// My Car - same spec as home dashboard
                // if (_uid != null)
                //   StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                //     stream: FirebaseFirestore.instance
                //         .collection('users')
                //         .doc(_uid)
                //         .collection('cars')
                //         .orderBy('createdAt', descending: true)
                //         .limit(1)
                //         .snapshots(),
                //     builder: (context, snapshot) {
                //       if (snapshot.connectionState == ConnectionState.waiting) {
                //         return const SizedBox.shrink();
                //       }
                //       if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                //         return const SizedBox.shrink();
                //       }
                //       final carData = Map<String, dynamic>.from(
                //         snapshot.data!.docs.first.data(),
                //       );
                //       return Container(
                //         width: double.infinity,
                //         padding: EdgeInsets.all(20.adaptSize),
                //         decoration: BoxDecoration(
                //           color: AppColors.cardBackground,
                //           borderRadius: BorderRadius.circular(16.adaptSize),
                //           border: Border.all(color: AppColors.border, width: 1),
                //         ),
                //         child: Column(
                //           crossAxisAlignment: CrossAxisAlignment.start,
                //           children: [
                //             Row(
                //               children: [
                //                 Icon(
                //                   Icons.directions_car,
                //                   size: 20.fSize,
                //                   color: AppColors.primaryBlue,
                //                 ),
                //                 Gap.h(10),
                //                 AppText(
                //                   'My Car',
                //                   size: 16.fSize,
                //                   fontWeight: FontWeight.bold,
                //                   color: AppColors.textPrimary,
                //                 ),
                //               ],
                //             ),
                //             Gap.v(16),
                //             CarSpecContent(carData: carData),
                //           ],
                //         ),
                //       );
                //     },
                //   ),

                Gap.v(28),

                /// Personal Information card (expandable)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16.adaptSize),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          AppRouter.push(context, RouteNames.editProfile);
                        },
                        borderRadius: BorderRadius.circular(16.adaptSize),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.h,
                            vertical: 16.v,
                          ),
                          child: Row(
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
                              Icon(
                                Icons.chevron_right,
                                color: AppColors.textSecondary,
                                size: 24.fSize,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Gap.v(24),

                /// Registrations Tile
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16.adaptSize),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: InkWell(
                    onTap: () {
                      AppRouter.push(context, RouteNames.registrations);
                    },
                    borderRadius: BorderRadius.circular(16.adaptSize),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.h,
                        vertical: 16.v,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40.adaptSize,
                            height: 40.adaptSize,
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.description_outlined,
                              color: AppColors.primaryBlue,
                              size: 20.fSize,
                            ),
                          ),
                          Gap.h(12),
                          Expanded(
                            child: AppText(
                              'Registrations',
                              size: 15.fSize,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: AppColors.textSecondary,
                            size: 24.fSize,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Gap.v(24),

                /// Privacy & Permissions Tile
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16.adaptSize),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: InkWell(
                    onTap: () {
                      AppRouter.push(context, RouteNames.privacyPolicy);
                    },
                    borderRadius: BorderRadius.circular(16.adaptSize),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.h,
                        vertical: 16.v,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40.adaptSize,
                            height: 40.adaptSize,
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.privacy_tip_outlined,
                              color: AppColors.primaryBlue,
                              size: 20.fSize,
                            ),
                          ),
                          Gap.h(12),
                          Expanded(
                            child: AppText(
                              'Privacy & policy',
                              size: 15.fSize,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: AppColors.textSecondary,
                            size: 24.fSize,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Gap.v(24),

                      Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16.adaptSize),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: InkWell(
                    onTap: () {
                      AppRouter.push(context, RouteNames.termsCondition);
                    },
                    borderRadius: BorderRadius.circular(16.adaptSize),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.h,
                        vertical: 16.v,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40.adaptSize,
                            height: 40.adaptSize,
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.description_outlined,
                              color: AppColors.primaryBlue,
                              size: 20.fSize,
                            ),
                          ),
                          Gap.h(12),
                          Expanded(
                            child: AppText(
                              'Terms & Conditions',
                              size: 15.fSize,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: AppColors.textSecondary,
                            size: 24.fSize,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Gap.v(24),


                

                /// Logout Button
                CustomButton(
                  text: 'Logout',
                  onPressed: _isLoggingOut ? () {} : _showLogoutDialog,
                  backgroundColor: AppColors.cardBackground,
                  textColor: AppColors.textPrimary,
                  borderColor: AppColors.border,
                  icon: Icons.logout,
                  isDisabled: _isLoggingOut,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}