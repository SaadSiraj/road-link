import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/routes_name.dart';
import '../../core/shared/app_button.dart';
import '../../core/shared/app_text.dart';
import '../../core/shared/app_textfield.dart';
import '../../core/utils/size_utils.dart';
import '../../viewmodels/auth_viewmodel.dart';

class SignInView extends StatelessWidget {
  const SignInView({super.key});

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
                            return ReusableTextField(
                              controller: auth.phoneController,
                              label: 'Phone Number',
                              hintText: 'Enter your Phone Number',
                              keyboardType: TextInputType.phone,
                              suffixIcon: Icons.call,
                              borderRadius: 16.adaptSize,
                              fillColor: AppColors.textFieldFillColor,
                              textColor: AppColors.textPrimary,
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
                              text: auth.isLoading ? 'Sending OTP...' : 'Sign In',
                              onPressed: auth.isLoading
                                  ? () {}
                                  : () {
                                      _handleSignIn(context, auth);
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

  void _handleSignIn(BuildContext context, AuthViewModel auth) {
    final rawPhone = auth.phoneController.text.trim();
    if (rawPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your phone number.'),
        ),
      );
      return;
    }

    final formattedPhone = _formatPhoneNumber(rawPhone);
    if (formattedPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid phone number.'),
        ),
      );
      return;
    }

    auth.setPhoneNumber(formattedPhone);
    auth.signInAndSendOtp(
      formattedPhone,
      () {
        // Navigate to verify code screen
        Navigator.pushNamed(
          context,
          RouteNames.verifyCode,
        );
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
          ),
        );
      },
    );
  }

  String _formatPhoneNumber(String phone) {
    final trimmed = phone.replaceAll(RegExp(r'\s+'), '');
    if (trimmed.startsWith('+')) {
      return trimmed;
    }

    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) return '';

    if (digitsOnly.startsWith('0')) {
      return '+61${digitsOnly.substring(1)}';
    }

    return '+$digitsOnly';
  }
}
