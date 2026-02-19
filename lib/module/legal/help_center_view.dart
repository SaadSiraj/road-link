import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/shared/app_text.dart';
import '../../core/utils/size_utils.dart';

class HelpCenterView extends StatelessWidget {
  const HelpCenterView({super.key});

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
              child: const Icon(Icons.help_outline_rounded,
                  color: AppColors.primaryBlue, size: 20),
            ),
            const SizedBox(width: 10),
            AppText(
              'Help Center',
              color: AppColors.textPrimary,
              size: 20.fSize,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
                children: const [
                  AppText(
                    'Need help with Platoscan?',
                    size: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  SizedBox(height: 8),
                  AppText(
                    'Find quick answers to common questions or reach out to our support team.',
                    color: AppColors.textSecondary,
                    size: 13,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section label
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: AppText(
                'Browse Topics',
                size: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),

            _buildHelpCard(
              icon: Icons.person_outline_rounded,
              title: 'Account & Profile',
              description:
                  'Create an account, update your profile, and manage your personal information.',
              badge: '3 articles',
            ),

            _buildHelpCard(
              icon: Icons.directions_car_outlined,
              title: 'Car & Plate Registration',
              description:
                  'Add, verify, or update your vehicle and licence plate details.',
              badge: '5 articles',
            ),

            _buildHelpCard(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Chats & Notifications',
              description:
                  'Understand how chat requests work, how to respond, and how notifications are sent.',
              badge: '4 articles',
            ),

            _buildHelpCard(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy & Safety',
              description:
                  'How we protect your data and how to stay safe while using Platoscan.',
              badge: '2 articles',
            ),

            const SizedBox(height: 20),

            // Contact Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
                          'Still need help?',
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          size: 15,
                        ),
                        const SizedBox(height: 6),
                        const AppText(
                          'Can\'t find what you\'re looking for? Contact our support team directly.',
                          color: AppColors.textSecondary,
                          size: 13,
                        ),
                        const SizedBox(height: 10),
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

  Widget _buildHelpCard({
    required IconData icon,
    required String title,
    required String description,
    required String badge,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primaryBlue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppText(
                          title,
                          size: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSoft,
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: AppColors.border, width: 1),
                        ),
                        child: AppText(
                          badge,
                          size: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  AppText(
                    description,
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}