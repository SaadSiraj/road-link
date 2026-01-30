import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../app_text.dart';

class AuthFooter extends StatelessWidget {
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;
  final VoidCallback onHelpTap;

  const AuthFooter({
    super.key,
    required this.onTermsTap,
    required this.onPrivacyTap,
    required this.onHelpTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _footerButton("Terms of Service", onTermsTap),
        _divider(),
        _footerButton("Privacy Policy", onPrivacyTap),
        _divider(),
        _footerButton("Help Center", onHelpTap),
      ],
    );
  }

  Widget _footerButton(String title, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      child: AppText(
        title,
        size: 14,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text("|"),
    );
  }
}
