import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roadlink/core/utils/size_utils.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/shared/app_text.dart';
import '../../../viewmodels/pending_car_requests_viewmodel.dart';
import 'car_request_detail_view.dart';

class PendingCarRequestsView extends StatefulWidget {
  const PendingCarRequestsView({super.key});

  @override
  State<PendingCarRequestsView> createState() => _PendingCarRequestsViewState();
}

class _PendingCarRequestsViewState extends State<PendingCarRequestsView> {
  @override
  void initState() {
    super.initState();
    // Load pending requests when view is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PendingCarRequestsViewModel>().loadPendingRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        title: AppText(
          'Pending Car Requests',
          size: 20.fSize,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: Consumer<PendingCarRequestsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.pendingRequests.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (viewModel.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48.fSize,
                    ),
                    Gap.v(16),
                    AppText(
                      viewModel.errorMessage!,
                      size: 14.fSize,
                      color: Colors.red,
                      align: TextAlign.center,
                    ),
                    Gap.v(16),
                    ElevatedButton(
                      onPressed: () {
                        viewModel.loadPendingRequests();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (viewModel.pendingRequests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64.fSize,
                    color: AppColors.textSecondary,
                  ),
                  Gap.v(16),
                  AppText(
                    'No Pending Requests',
                    size: 18.fSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  Gap.v(8),
                  AppText(
                    'All car requests have been processed',
                    size: 14.fSize,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await viewModel.refresh();
            },
            child: ListView.separated(
              padding: EdgeInsets.all(16.adaptSize),
              itemCount: viewModel.pendingRequests.length,
              separatorBuilder: (_, __) => Gap.v(12),
              itemBuilder: (context, index) {
                final request = viewModel.pendingRequests[index];
                return _PendingRequestCard(
                  userName: request.userName,
                  carName: request.carName,
                  requestDate: request.formattedDate,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CarRequestDetailsView(
                          request: request,
                        ),
                      ),
                    );
                    // Refresh the list when returning from detail view
                    if (mounted) {
                      viewModel.refresh();
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// 🔹 Pending Request Card
class _PendingRequestCard extends StatelessWidget {
  final String userName;
  final String carName;
  final String requestDate;
  final VoidCallback onTap;

  const _PendingRequestCard({
    required this.userName,
    required this.carName,
    required this.requestDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.adaptSize),
      child: Container(
        padding: EdgeInsets.all(16.adaptSize),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14.adaptSize),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            /// Icon
            Container(
              width: 44.adaptSize,
              height: 44.adaptSize,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.adaptSize),
              ),
              child: const Icon(Icons.pending_actions, color: Colors.orange),
            ),

            Gap.h(16),

            /// Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    userName,
                    size: 16.fSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  Gap.v(4),
                  AppText(
                    carName,
                    size: 14.fSize,
                    color: AppColors.textSecondary,
                  ),
                  Gap.v(4),
                  AppText(
                    'Requested on $requestDate',
                    size: 12.fSize,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),

            /// Status
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 6.v),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20.adaptSize),
              ),
              child: AppText(
                'Pending',
                size: 12.fSize,
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
