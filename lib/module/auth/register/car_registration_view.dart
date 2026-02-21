import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roadlink/core/utils/size_utils.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/routes_name.dart';
import '../../../core/shared/app_button.dart';
import '../../../core/shared/app_text.dart';
import '../../../core/shared/app_textfield.dart';
import '../../../core/shared/loading_dialogue.dart';
import '../../../module/user/chat/chat_detail_args.dart';
import '../../../module/user/dashboard/car_details_popup.dart';
import '../../../services/car_data_service.dart';
import '../../../services/chat_service.dart';
import '../../../viewmodels/car_registration_viewmodel.dart';

class CarRegistrationView extends StatelessWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  const CarRegistrationView({super.key, this.onNext, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.h, vertical: 24.v),
          child: CarRegistrationContent(onNext: onNext, onBack: onBack),
        ),
      ),
    );
  }
}

class CarRegistrationContent extends StatelessWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  const CarRegistrationContent({super.key, this.onNext, this.onBack});

  // Helper method to build dropdown
  Widget _buildDropdown({
    required BuildContext context,
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          size: 14.fSize,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        Gap.v(10),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.cardBackground,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
            size: 20.adaptSize,
          ),
          style: TextStyle(
            fontSize: 15.fSize,
            color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: '$label',
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.5),
              fontSize: 15.fSize,
            ),
            filled: true,
            fillColor: AppColors.textFieldFillColor,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20.h,
              vertical: 16.v,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.adaptSize),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.adaptSize),
              borderSide: BorderSide(color: AppColors.border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.adaptSize),
              borderSide: BorderSide(color: AppColors.primaryBlue, width: 1.5),
            ),
          ),
          items:
              items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 15.fSize,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
          onChanged: enabled ? onChanged : null,
          menuMaxHeight: 300,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CarRegistrationViewModel>(
      builder: (context, viewModel, child) {
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
                      Icons.directions_car_rounded,
                      color: AppColors.primaryBlue,
                      size: 32.adaptSize,
                    ),
                  ),

                  Gap.v(24),

                  /// Title
                  AppText(
                    'Car Registration',
                    size: 28.fSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),

                  Gap.v(12),

                  /// Subtitle
                  AppText(
                    'Enter your vehicle details for registration',
                    size: 15.fSize,
                    align: TextAlign.center,
                    color: AppColors.textSecondary,
                  ),

                  Gap.v(32),

                  /// Plate Number Field
                  ReusableTextField(
                    controller: viewModel.plateNumberController,
                    label: 'Plate Number',
                    hintText: 'eg: AB12CD3456',
                    keyboardType: TextInputType.text,
                    borderRadius: 12.adaptSize,
                    fillColor: AppColors.textFieldFillColor,
                    textColor: AppColors.textPrimary,
                    required: true,
                    validator: (value) => viewModel.validatePlateNumber(value),
                    onChanged: (value) {
                      if (viewModel.errorMessage != null && value.isNotEmpty) {
                        viewModel.errorMessage = null;
                      }
                    },
                  ),

                  Gap.v(24),

                  /// Row 1: Make & Model
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          context: context,
                          label: 'Make',
                          value: viewModel.selectedMake,
                          items: CarDataService.carMakes,
                          onChanged: (val) => viewModel.setMake(val),
                        ),
                      ),
                      Gap.h(16),
                      Expanded(
                        child: _buildDropdown(
                          context: context,
                          label: 'Model',
                          value: viewModel.selectedModel,
                          items:
                              viewModel.selectedMake != null
                                  ? (CarDataService.carModels[viewModel
                                          .selectedMake] ??
                                      [])
                                  : [],
                          onChanged: (val) => viewModel.setModel(val),
                          enabled: viewModel.selectedMake != null,
                        ),
                      ),
                    ],
                  ),

                  Gap.v(24),

                  /// Row 2: Year & Color
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          context: context,
                          label: 'Year',
                          value: viewModel.selectedYear,
                          items: CarDataService.carYears,
                          onChanged: (val) => viewModel.setYear(val),
                        ),
                      ),
                      Gap.h(16),
                      Expanded(
                        child: _buildDropdown(
                          context: context,
                          label: 'Color',
                          value: viewModel.selectedColor,
                          items: CarDataService.carColors,
                          onChanged: (val) => viewModel.setColor(val),
                        ),
                      ),
                    ],
                  ),

                  Gap.v(32),
                  const Divider(color: AppColors.border, thickness: 1),
                  Gap.v(24),

                  /// Car Images Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        'Car Images (Max 5)',
                        size: 14.fSize,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      Gap.v(12),
                      if (viewModel.selectedImages.isNotEmpty)
                        Container(
                          height: 100.adaptSize,
                          margin: EdgeInsets.only(bottom: 20.v),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: viewModel.selectedImages.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  Container(
                                    width: 100.adaptSize,
                                    height: 100.adaptSize,
                                    margin: EdgeInsets.only(right: 12.h),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        12.adaptSize,
                                      ),
                                      image: DecorationImage(
                                        image: FileImage(
                                          File(
                                            viewModel
                                                .selectedImages[index]
                                                .path,
                                          ),
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 6,
                                    right: 18,
                                    child: GestureDetector(
                                      onTap: () => viewModel.removeImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: AppColors.error,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                      /// Take Photo & Pick from Gallery
                      if (viewModel.selectedImages.length < 5)
                        Row(
                          children: [
                            Expanded(
                              child: _buildImageSourceButton(
                                icon: Icons.camera_alt_outlined,
                                label: 'Take Photo',
                                onTap: viewModel.takePhoto,
                              ),
                            ),
                            Gap.h(12),
                            Expanded(
                              child: _buildImageSourceButton(
                                icon: Icons.photo_library_outlined,
                                label: 'Gallery',
                                onTap: viewModel.pickImages,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  if (viewModel.errorMessage != null) ...[
                    Gap.v(16),
                    AppText(
                      viewModel.errorMessage!,
                      size: 12.fSize,
                      color: AppColors.error,
                    ),
                  ],

                  Gap.v(32),

                  /// Register Button
                  CustomButton(
                    text:
                        viewModel.isLoading ? 'Registering...' : 'Register Car',
                    onPressed:
                        viewModel.isLoading
                            ? () {}
                            : () {
                              LoadingDialog.show(
                                context,
                                message: 'Registering car...',
                              );
                              viewModel.saveCarData(
                                onSuccess: () {
                                  if (context.mounted) {
                                    LoadingDialog.hide(context);
                                    final status =
                                        viewModel.lastRegistrationStatus;
                                    if (status == 'pending') {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'your car is goes to admin pending approvel',
                                          ),
                                          backgroundColor:
                                              AppColors.primaryBlue,
                                        ),
                                      );
                                    }
                                  }
                                  onNext?.call();
                                },
                                onError: (_) {
                                  if (context.mounted)
                                    LoadingDialog.hide(context);
                                },
                                onAlreadyRegisteredByOther: (carData) {
                                  if (context.mounted)
                                    LoadingDialog.hide(context);
                                  _showCarDetailsDialog(context, carData);
                                },
                                onAlreadyRegisteredBySelf: () {
                                  if (context.mounted)
                                    LoadingDialog.hide(context);
                                  _showAlreadyRegisteredBySelfDialog(context);
                                },
                              );
                            },
                    backgroundColor: AppColors.primaryBlue,
                    textColor: AppColors.white,
                    borderRadius: 12.adaptSize,
                    height: 52.v,
                    width: double.infinity,
                    fontSize: 16.fSize,
                    fontWeight: FontWeight.bold,
                    isDisabled: viewModel.isLoading,
                  ),

                  Gap.v(14),

                  /// Back Button
                  CustomButton(
                    text: 'Back',
                    onPressed: onBack ?? () => Navigator.pop(context),
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
      },
    );
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.adaptSize),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.v),
        decoration: BoxDecoration(
          color: AppColors.textFieldFillColor,
          borderRadius: BorderRadius.circular(12.adaptSize),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryBlue, size: 24.adaptSize),
            Gap.v(6),
            AppText(
              label,
              size: 12.fSize,
              color: AppColors.white,
              fontWeight: FontWeight.w500,
            ),
          ],
        ),
      ),
    );
  }
}

/// Show car details popup when car is already registered by another user
void _showCarDetailsDialog(BuildContext context, Map<String, dynamic> carData) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder:
        (ctx) => CarDetailsPopup(
          carData: carData,
          isOwnCar: false,
          message:
              'This car already exists. You can chat with the registered owner.',
          onStartChat: () {
            Navigator.pop(ctx);
            _handleStartChat(context, carData);
          },
          onClose: () => Navigator.pop(ctx),
        ),
  );
}

/// Start chat with car owner
Future<void> _handleStartChat(
  BuildContext context,
  Map<String, dynamic> carData,
) async {
  final ownerId = carData['ownerId'] as String?;
  if (ownerId == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText('Owner information not found', color: Colors.white),
          backgroundColor: AppColors.error,
        ),
      );
    }
    return;
  }

  // Show loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder:
        (ctx) => Center(
          child: Container(
            padding: EdgeInsets.all(24.adaptSize),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16.adaptSize),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primaryBlue),
                Gap.v(16),
                AppText('Starting chat...', color: AppColors.textPrimary),
              ],
            ),
          ),
        ),
  );

  try {
    final chatService = ChatService();
    final plate = (carData['plateNumber'] ?? '').toString().toUpperCase();
    final make  = carData['make']?.toString()  ?? '';
    final model = carData['model']?.toString() ?? '';
    final year  = carData['year']?.toString()  ?? '';
    final vParts = [if (make.isNotEmpty) make, if (model.isNotEmpty) model, if (year.isNotEmpty) year];
    final vehicleLabel = [plate, if (vParts.isNotEmpty) vParts.join(' ')].where((s) => s.isNotEmpty).join(' · ');

    final conversation = await chatService.getOrCreateConversation(
      otherUserId: ownerId,
      vehicleLabel: vehicleLabel.isNotEmpty ? vehicleLabel : null,
    );

    if (!context.mounted) return;
    Navigator.pop(context); // Close loading dialog

    if (conversation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(
            'Unable to create conversation',
            color: Colors.white,
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Send car details as first message
    final color = carData['color'] ?? 'Unknown';
    final plateDisplay = plate.isNotEmpty ? plate : 'N/A';
    final makeDisplay  = make.isNotEmpty  ? make  : 'Unknown';
    final modelDisplay = model.isNotEmpty ? model : 'Unknown';
    final yearDisplay  = year.isNotEmpty  ? year  : 'N/A';
    final firstMessage =
        '📋 Vehicle Inquiry\n'
        '─────────────────\n'
        'Plate:  $plateDisplay\n'
        'Make:   $makeDisplay\n'
        'Model:  $modelDisplay\n'
        'Year:   $yearDisplay\n'
        'Colour: $color\n'
        '─────────────────\n'
        'A user has identified this vehicle and would like to get in touch. '
        'No personal information has been shared.';

    await chatService.sendMessage(
      conversationId: conversation.id,
      text: firstMessage,
    );

    // Get owner profile
    final profile = await chatService.getUserProfile(ownerId);

    if (!context.mounted) return;

    // Navigate to chat detail
    Navigator.pushNamed(
      context,
      RouteNames.chatDetail,
      arguments: ChatDetailArgs(
        conversationId: conversation.id,
        otherUserId: ownerId,
        otherUserName: profile['name'] ?? 'Car Owner',
        otherUserPhotoUrl: profile['photoUrl'],
      ),
    );
  } catch (e) {
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context); // Close loading dialog
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(
            'Error starting chat: ${e.toString()}',
            color: Colors.white,
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

void _showAlreadyRegisteredBySelfDialog(BuildContext context) {
  showDialog(
    context: context,
    builder:
        (ctx) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.adaptSize),
          ),
          title: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.primaryBlue,
                size: 28.fSize,
              ),
              Gap.h(12),
              AppText(
                'Already registered',
                size: 18.fSize,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ],
          ),
          content: AppText(
            'You already have this car registered with this plate number.',
            size: 14.fSize,
            color: AppColors.textSecondary,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: AppText(
                'OK',
                size: 16.fSize,
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
  );
}
