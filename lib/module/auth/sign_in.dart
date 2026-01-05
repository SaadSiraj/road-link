import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/shared/widgets/app_text.dart';
import '../../core/shared/widgets/app_button.dart';
import '../../core/shared/widgets/app_textfield.dart';
import '../../core/utils/size_utils.dart';

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
                  'RoadLink',
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
                        ReusableTextField(
                          label: 'Phone Number',
                          hintText: 'Enter your Phone Number',
                          keyboardType: TextInputType.phone,
                          borderRadius: 16.adaptSize,
                          fillColor: AppColors.cardBackground,
                          textColor: AppColors.textPrimary,
                        ),

                        Gap.v(24),

                        // Password Field
                        ReusableTextField(
                          label: 'Password',
                          hintText: 'Enter your Password',
                          obscureText: true,
                          borderRadius: 16.adaptSize,
                          fillColor: AppColors.cardBackground,
                          textColor: AppColors.textPrimary,
                        ),

                        Gap.v(40),

                        // Sign In Button
                        CustomButton(
                          text: 'Sign In',
                          onPressed: () {},
                          backgroundColor: AppColors.primaryBlue,
                          textColor: AppColors.white,
                          borderRadius: 8.adaptSize,
                          height: 50.v,
                          width: double.infinity,
                          fontSize: 16.fSize,
                          fontWeight: FontWeight.bold,
                        ),

                        Gap.v(32),

                        // New to RoadLink? section
                        Center(
                          child: Column(
                            children: [
                              AppText(
                                'New to RoadLink?',
                                size: 16.fSize,
                                color: AppColors.textSecondary,
                              ),

                              TextButton(
                                onPressed: () {},
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

                Gap.v(120),

                // Bottom links
                Row(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
