import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/shared/app_button.dart';
import '../../../core/shared/app_text.dart';
import '../../../core/utils/size_utils.dart';

/// Reusable car specification display (plate + make/model/year/color).
/// Used in [CarDetailsPopup] and profile screen for consistent car spec UI.
class CarSpecContent extends StatelessWidget {
  final Map<String, dynamic> carData;

  const CarSpecContent({super.key, required this.carData});

  @override
  Widget build(BuildContext context) {
    final plateNumber = carData['plateNumber'] ?? 'N/A';
    final make = carData['make'] ?? 'Unknown';
    final model = carData['model'] ?? 'Unknown';
    final year = carData['year'] ?? 'N/A';
    final color = carData['color'] ?? 'Unknown';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        /// Plate Number - Prominent Display
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.adaptSize),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryBlue.withOpacity(0.1),
                AppColors.primaryBlueDark.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16.adaptSize),
            border: Border.all(
              color: AppColors.primaryBlue.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              AppText(
                'Plate Number',
                size: 12.fSize,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              Gap.v(8),
              AppText(
                plateNumber.toString().toUpperCase(),
                size: 28.fSize,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlueDark,
                letterSpacing: 2,
              ),
            ],
          ),
        ),
        Gap.v(24),
        /// Car Information Grid
        Container(
          padding: EdgeInsets.all(20.adaptSize),
          decoration: BoxDecoration(
            color: AppColors.scaffoldBackground,
            borderRadius: BorderRadius.circular(16.adaptSize),
          ),
          child: Column(
            children: [
              _buildInfoRow(
                icon: Icons.commute,
                label: 'Make',
                value: make,
              ),
              Gap.v(16),
              Divider(color: AppColors.border, height: 1),
              Gap.v(16),
              _buildInfoRow(
                icon: Icons.drive_eta,
                label: 'Model',
                value: model,
              ),
              Gap.v(16),
              Divider(color: AppColors.border, height: 1),
              Gap.v(16),
              _buildInfoRow(
                icon: Icons.calendar_today,
                label: 'Year',
                value: year.toString(),
              ),
              Gap.v(16),
              Divider(color: AppColors.border, height: 1),
              Gap.v(16),
              _buildInfoRow(
                icon: Icons.palette,
                label: 'Color',
                value: color,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.adaptSize),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.adaptSize),
          ),
          child: Icon(
            icon,
            size: 20.fSize,
            color: AppColors.primaryBlue,
          ),
        ),
        Gap.h(16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                label,
                size: 12.fSize,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              Gap.v(4),
              AppText(
                value,
                size: 16.fSize,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CarDetailsPopup extends StatelessWidget {
  final Map<String, dynamic> carData;
  final VoidCallback onStartChat;
  final VoidCallback onClose;
  /// When true, shows OK button instead of Start Chat (e.g. user scanned their own car).
  final bool isOwnCar;
  /// Optional message shown above car details (e.g. "This car already exists" during registration).
  final String? message;

  const CarDetailsPopup({
    super.key,
    required this.carData,
    required this.onStartChat,
    required this.onClose,
    this.isOwnCar = false,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.h),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(24.adaptSize),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Header with close button
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24.h, vertical: 20.v),
              decoration: BoxDecoration(
                color: AppColors.primaryBlueDark,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.adaptSize),
                  topRight: Radius.circular(24.adaptSize),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.adaptSize),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8.adaptSize),
                        ),
                        child: Icon(
                          Icons.directions_car,
                          color: Colors.white,
                          size: 24.fSize,
                        ),
                      ),
                      Gap.h(12),
                      AppText(
                        'Car Details',
                        size: 20.fSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24.fSize,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            /// Car details content (same spec as profile)
            Padding(
              padding: EdgeInsets.all(24.adaptSize),
              child: Column(
                children: [
                  if (message != null && message!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.adaptSize,
                        vertical: 12.v,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.adaptSize),
                        border: Border.all(
                          color: AppColors.primaryBlue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 20.fSize,
                            color: AppColors.primaryBlue,
                          ),
                          Gap.h(12),
                          Expanded(
                            child: AppText(
                              message!,
                              size: 14.fSize,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Gap.v(20),
                  ],
                  CarSpecContent(carData: carData),
                  Gap.v(24),
                  /// Privacy Notice
                  Container(
                    padding: EdgeInsets.all(12.adaptSize),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.adaptSize),
                      border: Border.all(
                        color: AppColors.primaryBlue.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.privacy_tip_outlined,
                          size: 18.fSize,
                          color: AppColors.primaryBlue,
                        ),
                        Gap.h(8),
                        Expanded(
                          child: AppText(
                            'Owner details are kept private for security',
                            size: 12.fSize,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Gap.v(24),
                  /// Start Chat or OK button (OK when it's user's own car)
                  CustomButton(
                    text: isOwnCar ? 'OK' : 'Start Chat with Owner',
                    onPressed: isOwnCar ? onClose : onStartChat,
                    backgroundColor: AppColors.primaryBlue,
                    textColor: AppColors.white,
                    borderRadius: 12.adaptSize,
                    height: 50.v,
                    width: double.infinity,
                    fontSize: 16.fSize,
                    fontWeight: FontWeight.bold,
                    icon: isOwnCar ? Icons.check : Icons.chat_bubble_outline,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
