import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roadlink/core/utils/size_utils.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/shared/app_text.dart';
import '../../../core/shared/app_button.dart';
import '../../../viewmodels/pending_car_requests_viewmodel.dart';

class CarRequestDetailsView extends StatefulWidget {
  final PendingCarRequest? request;
  
  const CarRequestDetailsView({super.key, this.request});

  @override
  State<CarRequestDetailsView> createState() => _CarRequestDetailsViewState();
}

class _CarRequestDetailsViewState extends State<CarRequestDetailsView> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        title: AppText(
          'Car Request Details',
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
            /// 🔹 USER INFO
            _SectionCard(
              title: 'User Information',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow('Name', widget.request?.userName ?? 'Unknown'),
                  _InfoRow('Phone', widget.request?.userPhone ?? 'N/A'),
                ],
              ),
            ),

            Gap.v(16),

            /// 🔹 CAR DETAILS
            _SectionCard(
              title: 'Car Details',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow('Car Name', widget.request?.carName ?? 'N/A'),
                  _InfoRow('Year', widget.request?.year ?? 'N/A'),
                  _InfoRow('Color', widget.request?.color ?? 'N/A'),
                  _InfoRow('Number Plate', widget.request?.plateNumber ?? 'N/A'),
                ],
              ),
            ),

            Gap.v(24),

            /// 🔹 ACTION BUTTONS
            Consumer<PendingCarRequestsViewModel>(
              builder: (context, viewModel, child) {
                final isProcessing = _isProcessing || viewModel.isLoading;
                
                return Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Approve',
                        backgroundColor: AppColors.success,
                        textColor: Colors.white,
                        isDisabled: isProcessing || widget.request == null,
                        onPressed: isProcessing || widget.request == null
                            ? () {}
                            : () async {
                                if (widget.request == null) return;
                                
                                setState(() {
                                  _isProcessing = true;
                                });

                                final success = await viewModel.approveRequest(
                                  userId: widget.request!.userId,
                                  carId: widget.request!.carId,
                                );

                                if (!mounted) return;

                                setState(() {
                                  _isProcessing = false;
                                });

                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: AppText(
                                        'Car request approved successfully',
                                        color: AppColors.white,
                                      ),
                                      backgroundColor: AppColors.success,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                  Navigator.pop(context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: AppText(
                                        viewModel.errorMessage ?? 'Failed to approve request',
                                        color: AppColors.white,
                                      ),
                                      backgroundColor: AppColors.error,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
                      ),
                    ),
                    Gap.h(16),
                    Expanded(
                      child: CustomButton(
                        text: 'Reject',
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        isDisabled: isProcessing || widget.request == null,
                        onPressed: isProcessing || widget.request == null
                            ? () {}
                            : () async {
                                if (widget.request == null) return;
                                
                                setState(() {
                                  _isProcessing = true;
                                });

                                final success = await viewModel.rejectRequest(
                                  userId: widget.request!.userId,
                                  carId: widget.request!.carId,
                                );

                                if (!mounted) return;

                                setState(() {
                                  _isProcessing = false;
                                });

                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: AppText(
                                        'Car request rejected',
                                        color: AppColors.white,
                                      ),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                  Navigator.pop(context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: AppText(
                                        viewModel.errorMessage ?? 'Failed to reject request',
                                        color: AppColors.white,
                                      ),
                                      backgroundColor: AppColors.error,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
                      ),
                    ),
                  ],
                );
              },
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
