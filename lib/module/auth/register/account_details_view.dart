import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/shared/app_button.dart';
import '../../../core/shared/app_text.dart';
import '../../../core/shared/loading_dialogue.dart';
import '../../../core/utils/size_utils.dart';
import '../../../viewmodels/auth_viewmodel.dart';

class AccountDetailsView extends StatelessWidget {
  final VoidCallback? onNext;

  const AccountDetailsView({super.key, this.onNext});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.h, vertical: 24.v),
            child: AccountDetailsContent(onNext: onNext),
          ),
        ),
      ),
    );
  }
}

class AccountDetailsContent extends StatefulWidget {
  final VoidCallback? onNext;

  const AccountDetailsContent({super.key, this.onNext});

  @override
  State<AccountDetailsContent> createState() => _AccountDetailsContentState();
}

class _AccountDetailsContentState extends State<AccountDetailsContent> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _completePhoneNumber = '';
  bool _isPhoneValid = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AppText(message, color: AppColors.white),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _handleContinue(AuthViewModel auth) {
    if (auth.isLoading) return;

    // Check if phone number is valid and not empty
    if (_completePhoneNumber.isEmpty || !_isPhoneValid) {
      _showSnack(
        _completePhoneNumber.isEmpty
            ? 'Please enter your phone number.'
            : 'Please enter a valid phone number.',
      );
      return;
    }

    auth.setPhoneNumber(_completePhoneNumber);
    LoadingDialog.show(context, message: 'Sending OTP...');
    auth.checkUserAndSendOtp(
      _completePhoneNumber,
      () {
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
                  Icons.phone_iphone_rounded,
                  color: AppColors.primaryBlue,
                  size: 32.adaptSize,
                ),
              ),

              Gap.v(24),

              /// Title
              AppText(
                'Account Details',
                size: 28.fSize,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),

              Gap.v(12),

              /// Subtitle
              AppText(
                'Enter your phone number and create a password.',
                size: 15.fSize,
                align: TextAlign.center,
                color: AppColors.textSecondary,
              ),

              Gap.v(32),

              /// Phone Field
              IntlPhoneField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter your phone number',
                  filled: true,
                  fillColor: AppColors.textFieldFillColor,
                  counterText: '', // Hide default counter
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20.h,
                    vertical: 18.v,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.adaptSize),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.adaptSize),
                    borderSide: BorderSide(color: AppColors.border, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.adaptSize),
                    borderSide: BorderSide(
                      color: AppColors.primaryBlue,
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.adaptSize),
                    borderSide: BorderSide(
                      color: AppColors.error.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.adaptSize),
                    borderSide: BorderSide(color: AppColors.error, width: 1.5),
                  ),
                  labelStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14.fSize,
                  ),
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.4),
                    fontSize: 14.fSize,
                  ),
                  suffixIcon: Padding(
                    padding: EdgeInsets.only(right: 12.h),
                    child: Icon(
                      Icons.phone_android_rounded,
                      color: AppColors.textSecondary.withOpacity(0.6),
                      size: 20.adaptSize,
                    ),
                  ),
                ),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16.fSize,
                  fontWeight: FontWeight.w500,
                ),
                cursorColor: AppColors.primaryBlue,
                dropdownDecoration: BoxDecoration(
                  color: AppColors.textFieldFillColor,
                  borderRadius: BorderRadius.circular(12.adaptSize),
                ),
                dropdownTextStyle: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16.fSize,
                  fontWeight: FontWeight.w600,
                ),
                dropdownIcon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                  size: 20.adaptSize,
                ),
                flagsButtonPadding: EdgeInsets.only(left: 12.h),
                pickerDialogStyle: PickerDialogStyle(
                  backgroundColor: AppColors.cardBackground,
                  countryCodeStyle: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16.fSize,
                    fontWeight: FontWeight.w600,
                  ),
                  countryNameStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14.fSize,
                  ),
                  searchFieldCursorColor: AppColors.primaryBlue,
                  searchFieldInputDecoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.textFieldFillColor,
                    hintText: 'Search country',
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                      size: 20.adaptSize,
                    ),
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.5),
                      fontSize: 14.fSize,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.h,
                      vertical: 12.v,
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
                      borderSide: BorderSide(
                        color: AppColors.primaryBlue,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                invalidNumberMessage: 'Please enter a valid phone number',
                initialCountryCode: 'AU',
                onChanged: (phone) {
                  setState(() {
                    _completePhoneNumber = phone.completeNumber;
                    _isPhoneValid = phone.isValidNumber();
                  });
                },
              ),

              // Gap.v(20),

              /// Password Field
              // ReusableTextField(
              //   controller: _passwordController,
              //   label: 'Password',
              //   hintText: 'Create a Password',
              //   obscureText: true,
              //   suffixIcon: Icons.visibility_off,
              //   borderRadius: 14.adaptSize,
              //   fillColor: AppColors.textFieldFillColor,
              //   textColor: AppColors.textPrimary,
              // ),
              if (auth.errorMessage != null) ...[
                Gap.v(16),
                AppText(
                  auth.errorMessage!,
                  size: 12.fSize,
                  color: AppColors.error,
                ),
              ],

              Gap.v(28),

              /// Continue Button
              CustomButton(
                text: auth.isLoading ? 'Sending OTP' : 'Continue',
                onPressed: () => _handleContinue(auth),
                backgroundColor: AppColors.primaryBlue,
                textColor: AppColors.white,
                borderRadius: 10.adaptSize,
                height: 50.v,
                width: double.infinity,
                fontSize: 16.fSize,
                fontWeight: FontWeight.bold,
                isDisabled: auth.isLoading,
              ),

              Gap.v(16),

              /// Info Text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.privacy_tip_outlined,
                    size: 14,
                    color: Colors.white,
                  ),
                  Gap.h(6),
                  Expanded(
                    child: AppText(
                      "Your phone number is safe with us. We don't share it with anyone.",
                      size: 12.fSize,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
