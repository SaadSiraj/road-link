import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/shared/app_text.dart';
import '../../core/utils/size_utils.dart';

class TermsConditionView extends StatelessWidget {
  const TermsConditionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        forceMaterialTransparency: true,
        elevation: 0,
        backgroundColor: AppColors.scaffoldBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.description_outlined,
                  color: AppColors.primaryBlue, size: 20),
            ),
            const SizedBox(width: 10),
            AppText(
              'Terms & Conditions',
              color: AppColors.textPrimary,
              size: 20.fSize,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryBlue.withOpacity(0.2),
                    AppColors.primaryBlueDark.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryBlue.withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText(
                    'Platoscan Terms & Conditions',
                    size: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: const [
                      Icon(Icons.calendar_today_outlined,
                          size: 13, color: AppColors.textSecondary),
                      SizedBox(width: 5),
                      AppText(
                        'Effective Date: 5 February 2026',
                        color: AppColors.textSecondary,
                        size: 13,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const AppText(
                    'By downloading, accessing, or using Platoscan, you agree to comply with these Terms. '
                    'If you do not agree, please do not use the app.',
                    color: AppColors.textSecondary,
                    size: 13,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _buildSection(
              icon: Icons.person_outline_rounded,
              number: '01',
              title: 'Eligibility',
              points: const [
                _TermPoint(detail: 'You must be at least 18 years old to use Platoscan.'),
                _TermPoint(
                    detail:
                        'You must provide accurate and complete information during registration.'),
              ],
            ),

            _buildSection(
              icon: Icons.app_registration_rounded,
              number: '02',
              title: 'Account Registration',
              points: const [
                _TermPoint(
                    detail:
                        'Register using your valid phone number and verify your vehicle licence plate.'),
                _TermPoint(
                    detail:
                        'You are responsible for maintaining the confidentiality of your account credentials.'),
                _TermPoint(
                    detail:
                        'You must not share your account with others or impersonate another person.'),
              ],
            ),

            _buildSection(
              icon: Icons.tune_rounded,
              number: '03',
              title: 'Use of Services',
              body:
                  'Platoscan is designed for social interaction between drivers. You agree to:',
              points: const [
                _TermPoint(detail: 'Use the app for lawful purposes only.'),
                _TermPoint(detail: 'Respect other users\' privacy and consent.'),
                _TermPoint(detail: 'Avoid sending spam, harassment, or offensive content.'),
              ],
            ),

            _buildSection(
              icon: Icons.block_rounded,
              number: '04',
              title: 'Prohibited Activities',
              body: 'You must not:',
              points: const [
                _TermPoint(detail: 'Use Platoscan for illegal activities.'),
                _TermPoint(
                    detail:
                        'Upload or share false, misleading, or harmful content.'),
                _TermPoint(
                    detail:
                        'Attempt to hack, reverse-engineer, or disrupt the app\'s functionality.'),
                _TermPoint(detail: 'Collect or misuse other users\' personal data.'),
              ],
              isWarning: true,
            ),

            _buildSection(
              icon: Icons.shield_outlined,
              number: '05',
              title: 'Privacy',
              body:
                  'Your privacy is important to us. Please review our Privacy Policy to understand how we collect, use, and protect your data.',
            ),

            _buildSection(
              icon: Icons.chat_bubble_outline_rounded,
              number: '06',
              title: 'Messaging and Communication',
              points: const [
                _TermPoint(detail: 'Chat requests can be accepted or declined by recipients.'),
                _TermPoint(
                    detail:
                        'Do not misuse the messaging system for harassment or unsolicited promotions.'),
                _TermPoint(
                    detail:
                        'Platoscan reserves the right to suspend accounts that violate community guidelines.'),
              ],
            ),

            _buildSection(
              icon: Icons.workspace_premium_outlined,
              number: '07',
              title: 'Intellectual Property',
              body:
                  'All content, trademarks, and features of Platoscan are owned by us or licensed to us. '
                  'You may not copy, modify, or distribute any part of the app without prior written consent.',
            ),

            _buildSection(
              icon: Icons.gavel_rounded,
              number: '08',
              title: 'Limitation of Liability',
              body: 'Platoscan is provided "as is" without warranties of any kind. We are not liable for:',
              points: const [
                _TermPoint(detail: 'Any damages resulting from your use of the app.'),
                _TermPoint(detail: 'Interactions or disputes between users.'),
              ],
            ),

            _buildSection(
              icon: Icons.cancel_outlined,
              number: '09',
              title: 'Termination',
              body:
                  'We may suspend or terminate your account if you violate these Terms or engage in harmful behaviour.',
            ),

            _buildSection(
              icon: Icons.update_rounded,
              number: '10',
              title: 'Changes to Terms',
              body:
                  'We may update these Terms from time to time. Continued use of Platoscan after changes indicates your acceptance of the updated Terms.',
            ),

            // Contact Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.mail_outline_rounded,
                        color: AppColors.primaryBlue, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppText(
                          '11. Contact Us',
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          size: 15,
                        ),
                        const SizedBox(height: 6),
                        const AppText(
                          'For questions about these Terms, reach out to us at:',
                          color: AppColors.textSecondary,
                          size: 13,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const AppText(
                            'contact@platoscan.com',
                            color: AppColors.primaryBlue,
                            size: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String number,
    required String title,
    List<_TermPoint> points = const [],
    String? body,
    bool isWarning = false,
  }) {
    final Color accentColor =
        isWarning ? AppColors.warning : AppColors.primaryBlue;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isWarning
              ? AppColors.warning.withOpacity(0.25)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: accentColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppText(
                    '$number. $title',
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    size: 15,
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.divider, height: 1),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (body != null) ...[
                  AppText(body,
                      color: AppColors.textSecondary,
                      size: 13),
                  if (points.isNotEmpty) const SizedBox(height: 10),
                ],
                if (points.isNotEmpty)
                  ...points.map((p) => _buildPoint(p, accentColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoint(_TermPoint point, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppText(
              point.detail,
              color: AppColors.textSecondary,
              size: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _TermPoint {
  final String detail;
  const _TermPoint({required this.detail});
}