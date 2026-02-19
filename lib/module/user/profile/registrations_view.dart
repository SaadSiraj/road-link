import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roadlink/core/utils/size_utils.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/shared/app_button.dart';
import '../../../core/shared/app_text.dart';
import '../../../services/car_service.dart';
import '../../../viewmodels/car_registration_viewmodel.dart';
import '../../auth/register/car_registration_view.dart';

class RegistrationsView extends StatefulWidget {
  const RegistrationsView({super.key});

  @override
  State<RegistrationsView> createState() => _RegistrationsViewState();
}

class _RegistrationsViewState extends State<RegistrationsView> {
  final CarService _carService = CarService();
  String? _uid;
  String? _userName;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    _uid = currentUser?.uid;
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    if (_uid == null) return;
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(_uid).get();
      final data = doc.data();
      if (mounted && data != null) {
        setState(() {
          _userName =
              (data['name'] as String?)?.trim() ??
              FirebaseAuth.instance.currentUser?.displayName?.trim() ??
              'User';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _userName =
              FirebaseAuth.instance.currentUser?.displayName?.trim() ?? 'User';
        });
      }
    }
  }

  Future<void> _showDeleteDialog(String carId, String plateNumber) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: AppText(
              'Remove Registration',
              size: 20.fSize,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            content: AppText(
              'Are you sure you want to remove the registration for $plateNumber?',
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
                  'Remove',
                  size: 15.fSize,
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
    );

    if (shouldDelete == true && _uid != null) {
      try {
        await _carService.deleteCar(_uid!, carId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: AppText(
                'Car registration removed successfully',
                color: AppColors.white,
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: AppText(
                'Failed to remove registration. Please try again.',
                color: AppColors.white,
              ),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _showAddRegistrationBottomSheet() {
    final viewModel = Provider.of<CarRegistrationViewModel>(
      context,
      listen: false,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.scaffoldBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SizedBox(
            height: MediaQuery.of(context).size.height * 0.9,
            child: Column(
              children: [
                /// Header
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.h,
                    vertical: 16.v,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    border: Border(
                      bottom: BorderSide(color: AppColors.border, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(
                        'Add New Registration',
                        size: 18.fSize,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: AppColors.textSecondary,
                          size: 24.fSize,
                        ),
                        onPressed: () {
                          viewModel.resetForm();
                          Navigator.pop(context);
                        },
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
                      builder: (context, viewModel, child) {
                        return CarRegistrationContent(
                          onNext: () {
                            Navigator.pop(context);
                            final status = viewModel.lastRegistrationStatus;
                            final isPending = status == 'pending';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: AppText(
                                  isPending
                                      ? 'your car is goes to admin pending approvel'
                                      : 'Car registered successfully!',
                                  color: AppColors.white,
                                ),
                                backgroundColor:
                                    isPending
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
    ).then((_) {
      viewModel.resetForm();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          backgroundColor: AppColors.scaffoldBackground,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: AppText(
            'Please log in to view registrations',
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

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
              Icons.description_outlined,
              color: AppColors.textPrimary,
              size: 24.fSize,
            ),
            SizedBox(width: 12.h),
            AppText(
              'Registrations',
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
              /// Your Car Registrations Section (Expandable)
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
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      borderRadius: BorderRadius.circular(16.adaptSize),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.h,
                          vertical: 16.v,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: AppText(
                                'Your Car Registrations',
                                size: 15.fSize,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Icon(
                              _isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: AppColors.textSecondary,
                              size: 24.fSize,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isExpanded) ...[
                      Divider(color: AppColors.border, height: 1),
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(_uid)
                                .collection('cars')
                                .orderBy('createdAt', descending: true)
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Padding(
                              padding: EdgeInsets.all(16.adaptSize),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Padding(
                              padding: EdgeInsets.all(16.adaptSize),
                              child: Center(
                                child: AppText(
                                  'Error loading registrations',
                                  color: AppColors.error,
                                ),
                              ),
                            );
                          }

                          final cars = snapshot.data?.docs ?? [];

                          if (cars.isEmpty) {
                            return Padding(
                              padding: EdgeInsets.all(16.adaptSize),
                              child: Center(
                                child: AppText(
                                  'No registered cars yet',
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: cars.length,
                            itemBuilder: (context, index) {
                              final car = cars[index].data();
                              final carId = cars[index].id;
                              final plateNumber =
                                  car['plateNumber'] as String? ?? '';
                              final make = car['make'] as String? ?? '';
                              final model = car['model'] as String? ?? '';
                              final status =
                                  car['status'] as String? ?? 'approved';
                              final carInfo = '$make $model | $plateNumber';
                              final isPending = status == 'pending';

                              return Column(
                                children: [
                                  if (index > 0)
                                    Divider(color: AppColors.border, height: 1),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.h,
                                      vertical: 12.v,
                                    ),
                                    child: Row(
                                      children: [
                                        /// Avatar
                                        CircleAvatar(
                                          radius: 20.adaptSize,
                                          backgroundColor: AppColors.primaryBlue
                                              .withOpacity(0.15),
                                          child: Icon(
                                            Icons.person,
                                            color: AppColors.primaryBlue,
                                            size: 20.fSize,
                                          ),
                                        ),
                                        SizedBox(width: 12.h),

                                        /// Name and Car Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              AppText(
                                                _userName ?? 'User',
                                                size: 15.fSize,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                              SizedBox(height: 4.v),
                                              AppText(
                                                carInfo,
                                                size: 13.fSize,
                                                color: AppColors.textSecondary,
                                              ),
                                              SizedBox(height: 6.v),

                                              /// Status Badge
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 10.h,
                                                  vertical: 4.v,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      isPending
                                                          ? Colors.orange
                                                              .withOpacity(0.2)
                                                          : AppColors.success
                                                              .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color:
                                                        isPending
                                                            ? Colors.orange
                                                            : AppColors.success,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width: 6.adaptSize,
                                                      height: 6.adaptSize,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            isPending
                                                                ? Colors.orange
                                                                : AppColors
                                                                    .success,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    SizedBox(width: 6.h),
                                                    AppText(
                                                      isPending
                                                          ? 'Pending Approval'
                                                          : 'Approved',
                                                      size: 11.fSize,
                                                      color:
                                                          isPending
                                                              ? Colors.orange
                                                              : AppColors
                                                                  .success,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        /// Menu Button
                                        PopupMenuButton<String>(
                                          icon: Icon(
                                            Icons.more_vert,
                                            color: AppColors.textSecondary,
                                            size: 20.fSize,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          color: AppColors.cardBackground,
                                          onSelected: (value) {
                                            if (value == 'remove') {
                                              _showDeleteDialog(
                                                carId,
                                                plateNumber,
                                              );
                                            }
                                          },
                                          itemBuilder:
                                              (context) => [
                                                PopupMenuItem(
                                                  value: 'remove',
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.delete_outline,
                                                        color: AppColors.error,
                                                        size: 18.fSize,
                                                      ),
                                                      SizedBox(width: 8.h),
                                                      AppText(
                                                        'Remove Registration',
                                                        size: 14.fSize,
                                                        color: AppColors.error,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 24.v),

              /// Add New Registration Button
              CustomButton(
                text: 'Add New Registration',
                onPressed: _showAddRegistrationBottomSheet,
                backgroundColor: AppColors.primaryBlue,
                textColor: AppColors.white,
                icon: Icons.description,
                borderRadius: 12.adaptSize,
                height: 50.v,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
