import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/routes_name.dart';
import '../../../core/shared/app_text.dart';
import '../../../core/shared/widgets/step_progress_indicator.dart';
import '../../../core/utils/size_utils.dart';
import 'account_details_view.dart';
import 'car_registration_view.dart';
import 'complete_profile_view.dart';
import 'verify_code_view.dart';

class RegistrationView extends StatefulWidget {
  const RegistrationView({super.key});

  @override
  State<RegistrationView> createState() => _RegistrationViewState();
}

class _RegistrationViewState extends State<RegistrationView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Navigate to home or complete registration
      Navigator.pushReplacementNamed(context, RouteNames.baseNavigation);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: 18.h),
        child: Row(
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
      ),
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Step Progress Indicator
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.h, vertical: 24.v),
              child: StepProgressIndicator(
                currentStep: _currentPage,
                stepLabels: ['Account', 'Verify', 'Profile', 'Car Plate'],
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _totalPages,
                itemBuilder: (context, index) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.h,
                      vertical: 24.v,
                    ),
                    child: _buildPageContent(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent(int index) {
    switch (index) {
      case 0:
        return AccountDetailsContent(onNext: _nextPage);
      case 1:
        return VerifyCodeContent(onNext: _nextPage);
      case 2:
        return CompleteProfileContent(onNext: _nextPage, onBack: _previousPage);
      case 3:
        return CarRegistrationContent(onNext: _nextPage, onBack: _previousPage);
      default:
        return const SizedBox();
    }
  }
}
