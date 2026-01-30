import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roadlink/core/utils/size_utils.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/routes/routes_name.dart';
import '../../../core/shared/app_text.dart';
import '../../../core/shared/app_textfield.dart';
import '../../../services/car_service.dart';
import '../../../viewmodels/car_registration_viewmodel.dart';
import '../../../viewmodels/home_dashboard_viewmodel.dart';
import '../../auth/register/car_registration_view.dart';

class HomeDashboardView extends StatefulWidget {
  const HomeDashboardView({super.key});

  @override
  State<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<HomeDashboardView> {
  final TextEditingController _plateNumberController = TextEditingController();
  bool _isManualEntry = false;

  String _getGreeting(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 21) return 'Good evening';
    return 'Good night';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeDashboardViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.h, vertical: 24.v),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔹 TOP HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    /// App Name
                    AppText(
                      'Car',
                      size: 24.fSize,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),

                    /// Right side icons
                    Row(
                      children: [
                        /// Notification Bell with Badge
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: Icon(
                                Icons.notifications_outlined,
                                size: 24.fSize,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                width: 18.adaptSize,
                                height: 18.adaptSize,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B35), // Orange
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: AppText(
                                    '3',
                                    size: 10.fSize,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        Gap.h(12),

                        /// Profile Picture
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, RouteNames.profile);
                          },
                          child: _buildProfilePicture(context, viewModel),
                        ),
                      ],
                    ),
                  ],
                ),
                Divider(color: AppColors.border, thickness: 1),

                Gap.v(24),

                /// 🔹 USER INFORMATION SECTION
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Greeting
                    AppText(
                      _getGreeting(DateTime.now()),
                      size: 14.fSize,
                      color: AppColors.textSecondary,
                    ),

                    Gap.v(8),

                    /// Name with Online Status and Register Car Button
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              _buildUserName(context, viewModel),
                              Gap.h(12),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.h,
                                  vertical: 4.v,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(12.adaptSize),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6.adaptSize,
                                      height: 6.adaptSize,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Gap.h(6),
                                    AppText(
                                      'Online',
                                      size: 12.fSize,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Gap.h(12),
                        /// Register Car Button
                        GestureDetector(
                          onTap: () {
                            final uid = viewModel.currentUserId;
                            if (uid != null) {
                              final carService = CarService();
                              carService.logCarRegistrationButtonTap(uid);
                            }
                            _showCarRegistrationBottomSheet(context);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.h,
                              vertical: 8.v,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue,
                              borderRadius: BorderRadius.circular(8.adaptSize),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.directions_car,
                                  size: 16.fSize,
                                  color: Colors.white,
                                ),
                                Gap.h(6),
                                AppText(
                                  'Register Car',
                                  size: 12.fSize,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    Gap.v(12),

                    /// Car Info
                    _buildCarInfo(context, viewModel),
                  ],
                ),

                Gap.v(24),

                /// 🔹 METRICS SECTION (Scans & Chats)
                Row(
                  children: [
                    /// Scans Card
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(20.adaptSize),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0x4A1A56DB), // #1A56DB4A
                              const Color(0x4A00E676), // #00E6764A
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16.adaptSize),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            AppText(
                              '${viewModel.scansCount}',
                              size: 40.fSize,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                            Gap.v(4),
                            AppText(
                              'Scans',
                              size: 18.fSize,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ],
                        ),
                      ),
                    ),

                    Gap.h(16),

                    /// Chats Card
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(20.adaptSize),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0x4A1A56DB), // #1A56DB4A
                              const Color(0x4A00E676), // #00E6764A
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16.adaptSize),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            AppText(
                              '${viewModel.chatsCount}',
                              size: 40.fSize,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                            Gap.v(4),
                            AppText(
                              'Chats',
                              size: 18.fSize,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                Gap.v(24),

                /// 🔹 SCAN CAR PLATE SECTION
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24.adaptSize),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlueDark,
                    borderRadius: BorderRadius.circular(20.adaptSize),
                  ),
                  child: Column(
                    children: [
                      /// Grid Icon (4 squares)
                      Container(
                        width: 60.adaptSize,
                        height: 60.adaptSize,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.white, width: 1),
                          color: Colors.white.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.qr_code_scanner,
                          size: 24.fSize,
                          color: AppColors.white,
                        ),
                      ),

                      Gap.v(20),

                      /// Title
                      AppText(
                        'Scan Car Plate',
                        size: 22.fSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),

                      Gap.v(8),

                      /// Instructions
                      AppText(
                        'Point your camera at any car plate \nto connect with the driver.',
                        size: 14.fSize,
                        align: TextAlign.center,
                        color: AppColors.white,
                      ),

                      Gap.v(20),

                      /// Toggle between Scan and Manual Entry
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.adaptSize),
                        ),
                        padding: EdgeInsets.all(4.adaptSize),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildToggleOption(
                              context: context,
                              label: 'Scan',
                              icon: Icons.qr_code_scanner,
                              isSelected: !_isManualEntry,
                              onTap: () {
                                setState(() {
                                  _isManualEntry = false;
                                });
                              },
                            ),
                            Gap.h(8),
                            _buildToggleOption(
                              context: context,
                              label: 'Enter',
                              icon: Icons.edit,
                              isSelected: _isManualEntry,
                              onTap: () {
                                setState(() {
                                  _isManualEntry = true;
                                });
                                _showPlateNumberDialog(context);
                              },
                            ),
                          ],
                        ),
                      ),

                      Gap.v(24),

                      /// Start Scanning Button
                      Container(
                        width: 200.h,
                        height: 50.v,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30.adaptSize),
                          border: Border.all(
                            color: AppColors.primaryBlue,
                            width: 2,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              _handleStartScanning();
                            },
                            borderRadius: BorderRadius.circular(30.adaptSize),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  size: 20.fSize,
                                  color: AppColors.primaryBlue,
                                ),
                                Gap.h(8),
                                AppText(
                                  'Start Scanning',
                                  size: 16.fSize,
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Gap.v(32),

                // /// 🔹 RECENT CHATS SECTION
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     AppText(
                //       'Recent Chats',
                //       size: 20.fSize,
                //       fontWeight: FontWeight.bold,
                //       color: AppColors.textPrimary,
                //     ),
                //     GestureDetector(
                //       onTap: () {
                //         // View all chats logic
                //       },
                //       child: Row(
                //         mainAxisSize: MainAxisSize.min,
                //         children: [
                //           AppText(
                //             'View All',
                //             size: 14.fSize,
                //             color: AppColors.primaryBlueDark,
                //             fontWeight: FontWeight.w500,
                //           ),
                //           Gap.h(4),
                //           Icon(
                //             Icons.arrow_forward_ios,
                //             size: 12.fSize,
                //             color: AppColors.primaryBlue,
                //           ),
                //         ],
                //       ),
                //     ),
                //   ],
                // ),

                // Gap.v(20),

                // /// 🔹 CHAT LIST
                // Column(
                //   children: [
                //     _buildChatItem(
                //       name: 'John Ham',
                //       message: 'I found that mechanic you ....',
                //       time: '10:30 AM',
                //       unreadCount: 2,
                //     ),
                //     Gap.v(16),
                //     _buildChatItem(
                //       name: 'John Ham',
                //       message: 'I found that mechanic you ....',
                //       time: '10:30 AM',
                //       unreadCount: 2,
                //     ),
                //     Gap.v(16),
                //     _buildChatItem(
                //       name: 'John Ham',
                //       message: 'I found that mechanic you ....',
                //       time: '10:30 AM',
                //       unreadCount: 2,
                //     ),
                //   ],
                // ),

                // Gap.v(100), // Bottom padding for navigation bar
              ],
            ),
          ),
        ),
      ),
        );
      },
    );
  }

  /// Build profile picture widget
  Widget _buildProfilePicture(BuildContext context, HomeDashboardViewModel viewModel) {
    final userStream = viewModel.getUserStream();
    
    if (userStream == null) {
      return Container(
        width: 40.adaptSize,
        height: 40.adaptSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.border,
            width: 2,
          ),
        ),
        child: ClipOval(
          child: Image.asset(
            AppImages.userAvatar,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.cardBackground,
                child: Icon(
                  Icons.person,
                  color: AppColors.textSecondary,
                  size: 24.fSize,
                ),
              );
            },
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userStream,
      builder: (context, snapshot) {
        final photoUrl = viewModel.getUserPhotoUrl(snapshot.data);

        return Container(
          width: 40.adaptSize,
          height: 40.adaptSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.border,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: (photoUrl != null && photoUrl.isNotEmpty)
                ? CachedNetworkImage(
                    imageUrl: photoUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.cardBackground,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryBlue,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.cardBackground,
                      child: Icon(
                        Icons.person,
                        color: AppColors.textSecondary,
                        size: 24.fSize,
                      ),
                    ),
                  )
                : Image.asset(
                    AppImages.userAvatar,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.cardBackground,
                        child: Icon(
                          Icons.person,
                          color: AppColors.textSecondary,
                          size: 24.fSize,
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  /// Build user name widget
  Widget _buildUserName(BuildContext context, HomeDashboardViewModel viewModel) {
    final userStream = viewModel.getUserStream();
    
    if (userStream == null) {
      return AppText(
        viewModel.fallbackName,
        size: 28.fSize,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userStream,
      builder: (context, snapshot) {
        final displayName = viewModel.getUserName(snapshot.data);

        return AppText(
          displayName,
          size: 28.fSize,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        );
      },
    );
  }

  /// Build car info widget
  Widget _buildCarInfo(BuildContext context, HomeDashboardViewModel viewModel) {
    final carsStream = viewModel.getApprovedCarsStream();
    
    if (carsStream == null) {
      return Row(
        children: [
          Icon(
            Icons.directions_car,
            size: 18.fSize,
            color: AppColors.textSecondary,
          ),
          Gap.h(8),
          AppText(
            'No car registered',
            size: 14.fSize,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ],
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: carsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              Icon(
                Icons.directions_car,
                size: 18.fSize,
                color: AppColors.textSecondary,
              ),
              Gap.h(8),
              AppText(
                'Loading...',
                size: 14.fSize,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ],
          );
        }

        // Update viewModel with current cars
        final carInfo = viewModel.getCarInfo(snapshot.data);
        final approvedCars = viewModel.approvedCars;
        final hasMultipleCars = approvedCars.length > 1;

        return Row(
          children: [
            Icon(
              Icons.directions_car,
              size: 18.fSize,
              color: AppColors.textSecondary,
            ),
            Gap.h(8),
            Expanded(
              child: AppText(
                carInfo,
                size: 14.fSize,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (hasMultipleCars) ...[
              Gap.h(8),
              _buildCarDropdown(context, viewModel, approvedCars),
            ],
          ],
        );
      },
    );
  }

  /// Build car dropdown menu
  Widget _buildCarDropdown(
    BuildContext context,
    HomeDashboardViewModel viewModel,
    List<Map<String, dynamic>> cars,
  ) {
    return PopupMenuButton<String>(
      icon: Container(
        
        padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 4.v),
        decoration: BoxDecoration(
          
          color: AppColors.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6.adaptSize),
          border: Border.all(
            color: AppColors.primaryBlue.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.swap_horiz,
              size: 16.fSize,
              color: AppColors.primaryBlue,
            ),
            Gap.h(4),
            AppText(
              'Change',
              size: 12.fSize,
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.adaptSize),
      ),
      itemBuilder: (context) {
        return cars.asMap().entries.map((entry) {
          final index = entry.key;
          final car = entry.value;
          final carInfo = viewModel.getFormattedCarInfo(car);
          final isSelected = index == viewModel.selectedCarIndex;

          return PopupMenuItem<String>(
            value: index.toString(),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  size: 18.fSize,
                  color: isSelected
                      ? AppColors.primaryBlue
                      : AppColors.textSecondary,
                ),
                Gap.h(12),
                Expanded(
                  child: AppText(
                    carInfo,
                    size: 14.fSize,
                    color: isSelected
                        ? AppColors.primaryBlue
                        : AppColors.background,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      onSelected: (value) {
        final index = int.tryParse(value);
        if (index != null) {
          viewModel.selectCar(index);
        }
      },
    );
  }

  /// Build toggle option widget
  Widget _buildToggleOption({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.v),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8.adaptSize),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18.fSize,
              color: isSelected
                  ? AppColors.primaryBlueDark
                  : AppColors.white,
            ),
            Gap.h(6),
            AppText(
              label,
              size: 14.fSize,
              color: isSelected
                  ? AppColors.primaryBlueDark
                  : AppColors.white,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ],
        ),
      ),
    );
  }

  /// Handle start scanning
  void _handleStartScanning() {
    // TODO: Implement camera scanning logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AppText(
          'Camera scanning feature coming soon!',
          color: AppColors.white,
        ),
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  /// Show plate number entry dialog
  void _showPlateNumberDialog(BuildContext context) {
    _plateNumberController.clear();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.adaptSize),
        ),
        title: Row(
          children: [
            Icon(
              Icons.confirmation_number,
              color: AppColors.primaryBlue,
              size: 24.fSize,
            ),
            Gap.h(12),
            AppText(
              'Enter Plate Number',
              size: 20.fSize,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ],
        ),
        content: ReusableTextField(
          controller: _plateNumberController,
          hintText: 'Enter plate number',
          label: 'Plate Number',
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          prefixIcon: Icons.confirmation_number,
          fillColor: AppColors.textFieldFillColor,
          textColor: AppColors.textPrimary,
          borderRadius: 12.adaptSize,
          onSubmitted: (value) {
            Navigator.pop(dialogContext);
            _handlePlateNumberSearch(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: AppText(
              'Cancel',
              size: 16.fSize,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _handlePlateNumberSearch(_plateNumberController.text);
            },
            child: AppText(
              'Search',
              size: 16.fSize,
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Handle plate number search
  void _handlePlateNumberSearch(String plateNumber) {
    final trimmedPlate = plateNumber.trim();
    if (trimmedPlate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(
            'Please enter a plate number',
            color: AppColors.white,
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // TODO: Implement plate number search logic
    // This should search for the car by plate number and navigate to chat or show results
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AppText(
          'Searching for plate: $trimmedPlate',
          color: AppColors.white,
        ),
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  @override
  void dispose() {
    _plateNumberController.dispose();
    super.dispose();
  }

  void _showCarRegistrationBottomSheet(BuildContext context) {
    final viewModel = Provider.of<CarRegistrationViewModel>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: AppColors.scaffoldBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.adaptSize),
            topRight: Radius.circular(20.adaptSize),
          ),
        ),
        child: Column(
          children: [
            /// Handle bar
            Container(
              margin: EdgeInsets.only(top: 12.v),
              width: 40.adaptSize,
              height: 4.adaptSize,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2.adaptSize),
              ),
            ),

            /// Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.h, vertical: 16.v),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    'Register Car',
                    size: 20.fSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  IconButton(
                    onPressed: () {
                      viewModel.resetForm();
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.close,
                      color: AppColors.textPrimary,
                      size: 24.fSize,
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: AppColors.border, height: 1),

            /// Car Registration Form
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.adaptSize),
                child: Consumer<CarRegistrationViewModel>(
                  builder: (context, vm, child) {
                    return CarRegistrationContent(
                      onNext: () {
                        Navigator.pop(context);
                        final status = vm.lastRegistrationStatus;
                        final isPending = status == 'pending';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: AppText(
                              isPending
                                  ? 'Car registered! Pending admin approval.'
                                  : 'Car registered successfully!',
                              color: AppColors.white,
                            ),
                            backgroundColor: isPending
                                ? Colors.orange
                                : AppColors.success,
                            duration: const Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.only(
                              top: MediaQuery.of(context).padding.top + 16,
                              left: 16,
                              right: 16,
                            ),
                          ),
                        );
                      },
                      onBack: () {
                        viewModel.resetForm();
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      // Reset form when bottom sheet is dismissed
      viewModel.resetForm();
    });
  }

  /// Helper method to build chat item
  Widget _buildChatItem({
    required String name,
    required String message,
    required String time,
    required int unreadCount,
  }) {
    return Container(
      padding: EdgeInsets.all(16.adaptSize),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14.adaptSize),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          /// Profile Picture
          Container(
            width: 50.adaptSize,
            height: 50.adaptSize,
            decoration: BoxDecoration(shape: BoxShape.circle),
            child: ClipOval(
              child: Image.asset(
                AppImages.userAvatar,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.scaffoldBackground,
                    child: Icon(
                      Icons.person,
                      color: AppColors.textSecondary,
                      size: 28.fSize,
                    ),
                  );
                },
              ),
            ),
          ),

          Gap.h(16),

          /// Chat Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  name,
                  size: 16.fSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                Gap.v(4),
                AppText(
                  message,
                  size: 14.fSize,
                  color: AppColors.textSecondary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          Gap.h(12),

          /// Time and Unread Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText(time, size: 12.fSize, color: AppColors.textSecondary),
              Gap.v(8),
              Container(
                width: 20.adaptSize,
                height: 20.adaptSize,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: AppText(
                    unreadCount.toString(),
                    size: 11.fSize,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
