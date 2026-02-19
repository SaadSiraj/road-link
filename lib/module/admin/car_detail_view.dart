import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:roadlink/core/utils/size_utils.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/shared/app_text.dart';
import '../../../services/admin_service.dart';

class CarDetailsView extends StatefulWidget {
  final String userId;
  final String carId;

  const CarDetailsView({super.key, required this.userId, required this.carId});

  @override
  State<CarDetailsView> createState() => _CarDetailsViewState();
}

class _CarDetailsViewState extends State<CarDetailsView> {
  final AdminService _adminService = AdminService();
  late Future<Map<String, dynamic>?> _carDetailsFuture;

  @override
  void initState() {
    super.initState();
    _carDetailsFuture = _adminService.getCarDetails(
      userId: widget.userId,
      carId: widget.carId,
    );
  }

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
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _carDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  Gap.v(16),
                  AppText('Failed to load car details', color: Colors.red),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final imageUrls = data['imageUrls'] as List<String>? ?? [];
          final status = data['status'] as String;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.adaptSize),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔹 CAR IMAGES
                if (imageUrls.isNotEmpty) ...[
                  _SectionCard(
                    title: 'Car Images',
                    child: SizedBox(
                      height: 120.adaptSize,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: imageUrls.length,
                        separatorBuilder: (_, __) => Gap.h(12),
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(10.adaptSize),
                            child: Container(
                              width: 120.adaptSize,
                              decoration: BoxDecoration(
                                color: AppColors.backgroundSoft,
                                borderRadius: BorderRadius.circular(
                                  10.adaptSize,
                                ),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: imageUrls[index],
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Container(
                                      color: AppColors.backgroundSoft,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) =>
                                        const Icon(Icons.error),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Gap.v(16),
                ],

                /// 🔹 CAR INFO
                _SectionCard(
                  title: 'Car Information',
                  child: Column(
                    children: [
                      _InfoRow('Car Name', '${data['make']} ${data['model']}'),
                      _InfoRow('Year', '${data['year']}'),
                      _InfoRow('Color', '${data['color']}'),
                      _InfoRow('Plate Number', '${data['plateNumber']}'),
                    ],
                  ),
                ),

                Gap.v(16),

                /// 🔹 OWNER INFO
                _SectionCard(
                  title: 'Owner Information',
                  child: Column(
                    children: [
                      _InfoRow('Name', '${data['ownerName']}'),
                      _InfoRow('Phone', '${data['ownerPhone']}'),
                    ],
                  ),
                ),

                Gap.v(16),

                /// 🔹 APPROVAL STATUS
                _SectionCard(
                  title: 'Approval Status',
                  child: Row(
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        color: _getStatusColor(status),
                      ),
                      Gap.h(12),
                      AppText(
                        status.toUpperCase(),
                        size: 16.fSize,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(status),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.pending;
    }
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
