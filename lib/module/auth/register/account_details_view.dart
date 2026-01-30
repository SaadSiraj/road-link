import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/shared/app_button.dart';
import '../../../core/shared/app_text.dart';
import '../../../core/shared/app_textfield.dart';
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

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _handleContinue(AuthViewModel auth) {
    if (auth.isLoading) return;

    final rawPhone = auth.phoneController.text.trim();
    if (rawPhone.isEmpty) {
      _showSnack('Please enter your phone number.');
      return;
    }

    final formattedPhone = _formatPhoneNumber(rawPhone);
    if (formattedPhone.isEmpty) {
      _showSnack('Enter a valid phone number.');
      return;
    }

    auth.setPhoneNumber(formattedPhone);
    auth.checkUserAndSendOtp(
      formattedPhone,
      () {
        widget.onNext?.call();
      },
      onError: (error) {
        _showSnack(error);
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
            borderRadius: BorderRadius.circular(20.adaptSize),
          ),
          padding: EdgeInsets.all(20.adaptSize),
          child: Column(
            children: [
              /// Icon
              Container(
                height: 60.adaptSize,
                width: 60.adaptSize,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone_iphone,
                  color: Colors.white,
                  size: 28,
                ),
              ),

              Gap.v(20),

              /// Title
              AppText(
                'Account details',
                size: 26.fSize,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),

              Gap.v(8),

              /// Subtitle
              AppText(
                'Enter your phone number and create a password.',
                size: 14.fSize,
                align: TextAlign.center,
                color: AppColors.textSecondary,
              ),

              Gap.v(32),

              /// Phone Field
              ReusableTextField(
                controller: auth.phoneController,
                label: 'Phone Number',
                hintText: '04XX XXX XXX',
                keyboardType: TextInputType.phone,
                suffixIcon: Icons.call,
                borderRadius: 14.adaptSize,
                fillColor: AppColors.textFieldFillColor,
                textColor: AppColors.textPrimary,
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
                  color: Colors.redAccent,
                ),
              ],

              Gap.v(28),

              /// Continue Button
              CustomButton(
                text: auth.isLoading ? 'Sending OTP...' : 'Continue',
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
