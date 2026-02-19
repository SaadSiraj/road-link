import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roadlink/core/utils/size_utils.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/shared/app_button.dart';
import '../../../core/shared/app_text.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/routes/routes_name.dart';
import '../../../services/shared_preferences_service.dart';

class VerifyCodeView extends StatelessWidget {
  const VerifyCodeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.h, vertical: 24.v),
            child: const VerifyCodeContent(),
          ),
        ),
      ),
    );
  }
}

class VerifyCodeContent extends StatefulWidget {
  final VoidCallback? onNext;

  const VerifyCodeContent({super.key, this.onNext});

  @override
  State<VerifyCodeContent> createState() => _VerifyCodeContentState();
}

class _VerifyCodeContentState extends State<VerifyCodeContent> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  static const int _initialTimerSeconds = 59;
  Timer? _timer;
  int _remainingSeconds = _initialTimerSeconds;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _currentCode =>
      _controllers.map((controller) => controller.text).join();

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String get _formattedTimer {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  bool get _canResend => _remainingSeconds == 0;

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _initialTimerSeconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds == 0) {
        timer.cancel();
        setState(() {});
        return;
      }
      setState(() {
        _remainingSeconds--;
      });
    });
  }

  void _resendCode(AuthViewModel auth) {
    if (!_canResend || auth.isLoading) return;

    final phone = auth.phoneNumber;
    if (phone.isEmpty) {
      _showSnack('Phone number unavailable.');
      return;
    }

    auth.sendOtp(phone, () {
      _startTimer();
      _showSnack('Verification code resent.');
    }, onError: _showSnack);
  }

  void _submitCode(AuthViewModel auth) {
    if (auth.isLoading) return;

    if (_currentCode.length < 6) {
      _showSnack('Enter the 6-digit code');
      return;
    }

    auth.verifyOtp(_currentCode, () async {
      if (widget.onNext != null) {
        widget.onNext!.call();
        return;
      }

      // Check if user profile exists in Firestore
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        try {
          final userDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .get();

          final userData = userDoc.data();
          final hasName =
              userData?['name'] != null &&
              (userData!['name'] as String).trim().isNotEmpty;
          final isAdmin = userData?['isAdmin'] == true;

          if (hasName) {
            // Save login state to SharedPreferences
            await SharedPreferencesService.saveLoginState(
              isLoggedIn: true,
              isAdmin: isAdmin,
              userId: currentUser.uid,
            );

            // User profile exists, route based on admin flag
            if (isAdmin) {
              AppRouter.pushAndRemoveUntil(context, RouteNames.adminDashboard);
            } else {
              AppRouter.pushAndRemoveUntil(context, RouteNames.baseNavigation);
            }
          } else {
            // User profile doesn't exist, navigate to complete profile (registration flow)
            AppRouter.pushReplacement(context, RouteNames.completeProfile);
          }
        } catch (e) {
          // On error, default to complete profile
          AppRouter.pushReplacement(context, RouteNames.completeProfile);
        }
      } else {
        // No user, navigate to complete profile
        AppRouter.pushReplacement(context, RouteNames.completeProfile);
      }
    });
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
                  Icons.verified_user_rounded,
                  color: AppColors.primaryBlue,
                  size: 32.adaptSize,
                ),
              ),

              Gap.v(24),

              /// Title
              AppText(
                'Verify Code',
                size: 28.fSize,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),

              Gap.v(12),

              /// Subtitle
              AppText(
                'Enter the 6-digit code sent to your phone',
                size: 15.fSize,
                align: TextAlign.center,
                color: AppColors.textSecondary,
              ),

              Gap.v(20),

              /// Timer
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.v),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBackground.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12.adaptSize),
                  border: Border.all(
                    color: AppColors.border.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 18.fSize,
                      color: AppColors.textSecondary,
                    ),
                    Gap.h(8),
                    AppText(
                      _formattedTimer,
                      size: 14.fSize,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              ),

              Gap.v(32),

              /// 6-Digit Code Input
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                  (index) => SizedBox(
                    width: 46.adaptSize,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontSize: 22.fSize,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.textFieldFillColor,
                        contentPadding: EdgeInsets.symmetric(vertical: 14.v),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.adaptSize),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.adaptSize),
                          borderSide: BorderSide(
                            color: AppColors.border,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.adaptSize),
                          borderSide: BorderSide(
                            color: AppColors.primaryBlue,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        if (_currentCode.length == 6) {
                          _submitCode(auth);
                        }
                      },
                    ),
                  ),
                ),
              ),

              if (auth.errorMessage != null) ...[
                Gap.v(16),
                AppText(
                  auth.errorMessage!,
                  size: 12.fSize,
                  color: AppColors.error,
                ),
              ],

              Gap.v(32),

              /// Verify & Continue Button
              CustomButton(
                text: auth.isLoading ? 'Verifying...' : 'Verify & Continue',
                onPressed: () => _submitCode(auth),
                backgroundColor: AppColors.primaryBlue,
                textColor: AppColors.white,
                borderRadius: 12.adaptSize,
                height: 52.v,
                width: double.infinity,
                fontSize: 16.fSize,
                fontWeight: FontWeight.bold,
                isDisabled: auth.isLoading,
              ),

              Gap.v(24),

              /// Resend Code Button
              TextButton(
                onPressed: _canResend ? () => _resendCode(auth) : null,
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14.fSize,
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      const TextSpan(text: "Didn't receive code? "),
                      TextSpan(
                        text:
                            _canResend
                                ? 'Resend'
                                : 'Resend in $_formattedTimer',
                        style: TextStyle(
                          color:
                              _canResend
                                  ? AppColors.primaryBlue
                                  : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
