import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/shared/app_text.dart';
import '../../core/utils/size_utils.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

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
              child: const Icon(Icons.privacy_tip_outlined,
                  color: AppColors.primaryBlue, size: 20),
            ),
            const SizedBox(width: 10),
            AppText(
              'Privacy Policy',
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
                  AppText(
                    'Platoscan Privacy Policy',
                    size: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 5),
                      AppText(
                        'Effective Date: 5 February 2026',
                        color: AppColors.textSecondary,
                        size: 13,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppText(
                    'Platoscan values your privacy and is committed to protecting your personal information. '
                    'This policy explains how we collect, use, store, and share your data.',
                    color: AppColors.textSecondary,
                    size: 13,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _buildSection(
              icon: Icons.info_outline_rounded,
              number: '01',
              title: 'Information We Collect',
              points: const [
                _PolicyPoint(
                  icon: Icons.person_outline_rounded,
                  label: 'Account Information',
                  detail: 'Phone number, name, and profile details.',
                ),
                _PolicyPoint(
                  icon: Icons.directions_car_outlined,
                  label: 'Vehicle Information',
                  detail:
                      'Licence plate number, make, model, year, and colour of your registered vehicles.',
                ),
                _PolicyPoint(
                  icon: Icons.bar_chart_rounded,
                  label: 'Usage Data',
                  detail:
                      'Interactions within the app, chat requests, and messaging activity.',
                ),
                _PolicyPoint(
                  icon: Icons.phone_android_outlined,
                  label: 'Device Information',
                  detail:
                      'IP address, device type, operating system, and app version.',
                ),
                _PolicyPoint(
                  icon: Icons.camera_alt_outlined,
                  label: 'Camera Access',
                  detail:
                      'Used only for scanning licence plates. Images are not stored unless explicitly required.',
                ),
              ],
            ),

            _buildSection(
              icon: Icons.tune_rounded,
              number: '02',
              title: 'How We Use Your Information',
              points: const [
                _PolicyPoint(detail: 'Verify your identity and vehicle ownership.'),
                _PolicyPoint(detail: 'Enable plate-based communication between users.'),
                _PolicyPoint(detail: 'Provide messaging and notification services.'),
                _PolicyPoint(detail: 'Improve app functionality and user experience.'),
                _PolicyPoint(detail: 'Ensure safety and prevent misuse of the platform.'),
              ],
            ),

            _buildSection(
              icon: Icons.share_outlined,
              number: '03',
              title: 'Sharing of Information',
              points: const [
                _PolicyPoint(
                  label: 'With other users',
                  detail:
                      'Limited profile details when you accept a chat request.',
                ),
                _PolicyPoint(
                  label: 'With service providers',
                  detail: 'For hosting, analytics, and technical support.',
                ),
                _PolicyPoint(
                  label: 'For legal compliance',
                  detail:
                      'When required by law or to protect our rights and users\' safety.',
                ),
              ],
              note: 'We do not sell your personal data.',
            ),

            _buildSection(
              icon: Icons.shield_outlined,
              number: '04',
              title: 'Privacy Controls',
              points: const [
                _PolicyPoint(detail: 'Toggle profile visibility.'),
                _PolicyPoint(detail: 'Manage online status.'),
                _PolicyPoint(detail: 'Control who can send you chat requests.'),
                _PolicyPoint(detail: 'Register or remove multiple vehicles.'),
              ],
            ),

            _buildSection(
              icon: Icons.lock_outline_rounded,
              number: '05',
              title: 'Data Security',
              body:
                  'We implement industry-standard security measures to protect your data. However, no system is completely secure, and we cannot guarantee absolute protection.',
            ),

            _buildSection(
              icon: Icons.history_rounded,
              number: '06',
              title: 'Data Retention',
              body:
                  'We retain your data for as long as your account is active or as needed to provide services. You can request account deletion at any time.',
            ),

            _buildSection(
              icon: Icons.verified_user_outlined,
              number: '07',
              title: 'Your Rights',
              points: const [
                _PolicyPoint(detail: 'Access, correct, or delete your data.'),
                _PolicyPoint(detail: 'Restrict or object to certain processing.'),
                _PolicyPoint(detail: 'Request data portability.'),
              ],
              note: 'To exercise these rights, contact us at contact@platoscan.com.',
            ),

            _buildSection(
              icon: Icons.child_care_outlined,
              number: '08',
              title: 'Children\'s Privacy',
              body:
                  'Platoscan is not intended for individuals under 18. We do not knowingly collect data from minors.',
            ),

            _buildSection(
              icon: Icons.update_rounded,
              number: '09',
              title: 'Changes to This Policy',
              body:
                  'We may update this policy from time to time. Continued use of Platoscan after changes indicates your acceptance of the updated policy.',
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
                        AppText(
                          '10. Contact Us',
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          size: 15,
                        ),
                        const SizedBox(height: 6),
                        AppText(
                          'For questions or concerns about this Privacy Policy, reach out to us at:',
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
                          child: AppText(
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
    List<_PolicyPoint> points = const [],
    String? body,
    String? note,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
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
                    color: AppColors.primaryBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: AppColors.primaryBlue, size: 18),
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

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (body != null)
                  AppText(body, color: AppColors.textSecondary, size: 13),
                if (points.isNotEmpty)
                  ...points.map((p) => _buildPoint(p)),
                if (note != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primaryBlue.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.primaryBlue, size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppText(
                            note,
                            color: AppColors.primaryBlueLight,
                            size: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoint(_PolicyPoint point) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (point.icon != null) ...[
            Container(
              margin: const EdgeInsets.only(top: 1),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.backgroundSoft,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(point.icon, color: AppColors.textSecondary, size: 14),
            ),
            const SizedBox(width: 10),
          ] else ...[
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (point.label != null)
                  AppText(
                    point.label!,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    size: 13,
                  ),
                if (point.label != null) const SizedBox(height: 2),
                AppText(
                  point.detail,
                  color: AppColors.textSecondary,
                  size: 13,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyPoint {
  final IconData? icon;
  final String? label;
  final String detail;

  const _PolicyPoint({
    this.icon,
    this.label,
    required this.detail,
  });
}