import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/routes_name.dart';
import '../../core/shared/app_button.dart';
import '../../core/shared/app_text.dart';
import '../../core/utils/size_utils.dart';
import '../../viewmodels/auth_viewmodel.dart';

class SignInView extends StatefulWidget {
  const SignInView({super.key});

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  final TextEditingController _phoneController = TextEditingController();
  String _completePhoneNumber = '';
  bool _isPhoneValid = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0.h, vertical: 32.0.v),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Name/Title
                AppText(
                  'Car',
                  size: 40.fSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlueDark,
                ),

                Gap.v(40),

                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(20.adaptSize),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(15.adaptSize),
                    child: Column(
                      children: [
                        // Welcome Back Text
                        Gap.v(15),
                        AppText(
                          'Welcome Back',
                          size: 32.fSize,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),

                        Gap.v(8),

                        AppText(
                          'Sign in to your account',
                          size: 16.fSize,
                          color: AppColors.textSecondary,
                        ),

                        Gap.v(40),

                        // Phone Number Field
                        Consumer<AuthViewModel>(
                          builder: (context, auth, child) {
                            return IntlPhoneField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                hintText: 'Enter your phone number',
                                filled: true,
                                fillColor: AppColors.textFieldFillColor,
                                counterText:
                                    '', // Hide default counter for cleaner look
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20.h,
                                  vertical: 18.v,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    16.adaptSize,
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    16.adaptSize,
                                  ),
                                  borderSide: BorderSide(
                                    color: AppColors.border,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    16.adaptSize,
                                  ),
                                  borderSide: BorderSide(
                                    color: AppColors.primaryBlue,
                                    width: 1.5,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    16.adaptSize,
                                  ),
                                  borderSide: BorderSide(
                                    color: AppColors.error.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    16.adaptSize,
                                  ),
                                  borderSide: BorderSide(
                                    color: AppColors.error,
                                    width: 1.5,
                                  ),
                                ),
                                labelStyle: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14.fSize,
                                ),
                                hintStyle: TextStyle(
                                  color: AppColors.textSecondary.withOpacity(
                                    0.4,
                                  ),
                                  fontSize: 14.fSize,
                                ),
                                suffixIcon: Padding(
                                  padding: EdgeInsets.only(right: 12.h),
                                  child: Icon(
                                    Icons.phone_android_rounded,
                                    color: AppColors.textSecondary.withOpacity(
                                      0.6,
                                    ),
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
                                borderRadius: BorderRadius.circular(
                                  12.adaptSize,
                                ),
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
                                    color: AppColors.textSecondary.withOpacity(
                                      0.5,
                                    ),
                                    fontSize: 14.fSize,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16.h,
                                    vertical: 12.v,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      12.adaptSize,
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      12.adaptSize,
                                    ),
                                    borderSide: BorderSide(
                                      color: AppColors.border,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      12.adaptSize,
                                    ),
                                    borderSide: BorderSide(
                                      color: AppColors.primaryBlue,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                              invalidNumberMessage:
                                  'Please enter a valid phone number',
                              initialCountryCode: 'AU',
                              onChanged: (phone) {
                                setState(() {
                                  _completePhoneNumber = phone.completeNumber;
                                  _isPhoneValid = phone.isValidNumber();
                                });
                              },
                            );
                          },
                        ),

                        Gap.v(24),

                        // Error Message
                        Consumer<AuthViewModel>(
                          builder: (context, auth, child) {
                            if (auth.errorMessage != null) {
                              return Padding(
                                padding: EdgeInsets.only(bottom: 16.v),
                                child: AppText(
                                  auth.errorMessage!,
                                  size: 12.fSize,
                                  color: Colors.redAccent,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                        Gap.v(16),

                        // Sign In Button
                        Consumer<AuthViewModel>(
                          builder: (context, auth, child) {
                            return CustomButton(
                              text:
                                  auth.isLoading ? 'Sending OTP...' : 'Sign In',
                              onPressed:
                                  auth.isLoading
                                      ? () {}
                                      : () {
                                        _handleSignIn(auth);
                                      },
                              backgroundColor: AppColors.primaryBlue,
                              textColor: AppColors.white,
                              borderRadius: 8.adaptSize,
                              height: 50.v,
                              width: double.infinity,
                              fontSize: 16.fSize,
                              fontWeight: FontWeight.bold,
                              isDisabled: auth.isLoading,
                            );
                          },
                        ),

                        Gap.v(32),

                        // New to Car? section
                        Center(
                          child: Column(
                            children: [
                              AppText(
                                'New to Car?',
                                size: 16.fSize,
                                color: AppColors.textSecondary,
                              ),

                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    RouteNames.registration,
                                  );
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AppText(
                                      'Create an Account',
                                      size: 16.fSize,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.linkColor,
                                    ),
                                    Gap.h(8),
                                    Icon(
                                      Icons.arrow_forward,
                                      color: AppColors.linkColor,
                                      size: 16.fSize,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () {},
            child: AppText(
              'Terms of Service',
              size: 14.fSize,
              color: AppColors.textSecondary,
            ),
          ),

          TextButton(
            onPressed: () {},
            child: AppText(
              'Privacy Policy',
              size: 14.fSize,
              color: AppColors.textSecondary,
            ),
          ),

          TextButton(
            onPressed: () {},
            child: AppText(
              'Help Center',
              size: 14.fSize,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _handleSignIn(AuthViewModel auth) {
    // Check if phone number is valid and not empty
    if (_completePhoneNumber.isEmpty || !_isPhoneValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(
            _completePhoneNumber.isEmpty
                ? 'Please enter your phone number.'
                : 'Please enter a valid phone number.',
            color: AppColors.white,
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    auth.setPhoneNumber(_completePhoneNumber);
    auth.signInAndSendOtp(
      _completePhoneNumber,
      () {
        // Navigate to verify code screen
        Navigator.pushNamed(context, RouteNames.verifyCode);
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText(error, color: AppColors.white),
            backgroundColor: AppColors.error,
          ),
        );
      },
    );
  }
}
