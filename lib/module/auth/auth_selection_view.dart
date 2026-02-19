import 'package:flutter/material.dart';
import 'package:roadlink/core/utils/size_utils.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/shared/app_button.dart';
import '../../../core/shared/app_text.dart';
import '../../core/routes/app_router.dart';
import '../../core/routes/routes_name.dart';

class AuthSelectionView extends StatelessWidget {
  final VoidCallback? onSignIn;
  final VoidCallback? onRegister;

  const AuthSelectionView({super.key, this.onSignIn, this.onRegister});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.h, vertical: 24.v),
            child: AuthSelectionContent(
              onSignIn: onSignIn,
              onRegister: onRegister,
            ),
          ),
        ),
      ),
    );
  }
}

class AuthSelectionContent extends StatelessWidget {
  final VoidCallback? onSignIn;
  final VoidCallback? onRegister;

  const AuthSelectionContent({super.key, this.onSignIn, this.onRegister});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Gap.v(80),

        /// Welcome Title
        AppText(
          'Welcome to Platoscan',
          size: 36.fSize,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          align: TextAlign.center,
        ),

        Gap.v(16),

        /// Subtitle
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.h),
          child: AppText(
            'Connect using car plates\nMessage people by their licence plate in seconds.',
            size: 16.fSize,
            color: AppColors.textSecondary,
            align: TextAlign.center,
            height: 1.6,
          ),
        ),

        Gap.v(80),

        /// Main Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20.adaptSize),
          ),
          padding: EdgeInsets.all(32.adaptSize),
          child: Column(
            children: [
              /// Title
              AppText(
                'Get Started',
                size: 28.fSize,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),

              Gap.v(12),

              AppText(
                'Choose an option to continue',
                size: 15.fSize,
                color: AppColors.textSecondary,
              ),

              Gap.v(40),

              /// Register Button
              CustomButton(
                text: 'Create Account',
                onPressed:
                    onRegister ??
                    () {
                      Navigator.pushNamed(context, RouteNames.registration);
                    },
                backgroundColor: AppColors.primaryBlue,
                textColor: AppColors.white,
                borderRadius: 12.adaptSize,
                height: 56.v,
                width: double.infinity,
                fontSize: 16.fSize,
                fontWeight: FontWeight.bold,
              ),

              Gap.v(20),

              /// Sign In Button
              CustomButton(
                text: 'Sign In',
                onPressed:
                    onSignIn ??
                    () {
                      Navigator.pushNamed(context, RouteNames.signIn);
                    },
                backgroundColor: AppColors.cardBackground,
                textColor: AppColors.textPrimary,
                borderRadius: 12.adaptSize,
                height: 56.v,
                width: double.infinity,
                fontSize: 16.fSize,
                fontWeight: FontWeight.w600,
                borderColor: AppColors.border,
              ),
            ],
          ),
        ),

        Gap.v(32),

        /// Terms and Privacy
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.h),
          child: GestureDetector(
            onTap: () {
              AppRouter.push(context, RouteNames.termsCondition);
            },
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13.fSize,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'By continuing, you agree to our '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        Gap.v(40),
      ],
    );
  }
}
