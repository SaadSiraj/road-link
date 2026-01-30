import 'package:flutter/material.dart';
import 'package:roadlink/core/utils/size_utils.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/shared/app_text.dart';

class CarDetailsView extends StatelessWidget {
  final String? userId;
  final String? carId;
  
  const CarDetailsView({super.key, this.userId, this.carId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.scaffoldBackground,
        title: AppText(
          'Car Details',
          size: 20.fSize,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.adaptSize),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 CAR INFO
            _SectionCard(
              title: 'Car Information',
              child: Column(
                children: const [
                  _InfoRow('Car Name', 'Toyota Corolla'),
                  _InfoRow('Model', '2023'),
                  _InfoRow('Plate Number', 'ABC-1234'),
                ],
              ),
            ),

            Gap.v(16),

            /// 🔹 OWNER INFO
            _SectionCard(
              title: 'Owner Information',
              child: Column(
                children: const [
                  _InfoRow('Name', 'John Doe'),
                  _InfoRow('Email', 'john@gmail.com'),
                  _InfoRow('Total Cars', '3'),
                ],
              ),
            ),

            Gap.v(16),

            /// 🔹 APPROVAL STATUS
            _SectionCard(
              title: 'Approval Status',
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
                  Gap.h(12),
                  AppText(
                    'Approved',
                    size: 16.fSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔹 SECTION CARD
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.adaptSize),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14.adaptSize),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            title,
            size: 16.fSize,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          Gap.v(12),
          child,
        ],
      ),
    );
  }
}

/// 🔹 INFO ROW
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.v),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(label, size: 14.fSize, color: AppColors.textSecondary),
          AppText(
            value,
            size: 14.fSize,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}
