import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roadlink/core/utils/size_utils.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/shared/app_text.dart';
import '../../../viewmodels/user_detail_viewmodel.dart';

class UserDetailsView extends StatefulWidget {
  final String? userId;
  
  const UserDetailsView({super.key, this.userId});

  @override
  State<UserDetailsView> createState() => _UserDetailsViewState();
}

class _UserDetailsViewState extends State<UserDetailsView> {
  @override
  void initState() {
    super.initState();
    // Load user details when view is initialized
    if (widget.userId != null && widget.userId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<UserDetailViewModel>().loadUserDetails(widget.userId!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userId == null || widget.userId!.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.scaffoldBackground,
          title: AppText(
            'User Details',
            size: 20.fSize,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
        body: const Center(
          child: Text('Invalid user ID'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.scaffoldBackground,
        title: AppText(
          'User Details',
          size: 20.fSize,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: Consumer<UserDetailViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.userDetail == null) {
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
                        viewModel.loadUserDetails(widget.userId!);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (viewModel.userDetail == null) {
            return const Center(
              child: Text('User not found'),
            );
          }

          final user = viewModel.userDetail!;

          return RefreshIndicator(
            onRefresh: () async {
              await viewModel.refresh(widget.userId!);
            },
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.adaptSize),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🔹 USER PROFILE
                  Container(
                    padding: EdgeInsets.all(16.adaptSize),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(14.adaptSize),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32.adaptSize,
                          backgroundColor:
                              AppColors.primaryBlue.withOpacity(0.15),
                          child: Icon(
                            Icons.person,
                            size: 32.fSize,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        Gap.h(16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                user.name,
                                size: 18.fSize,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              Gap.v(4),
                              AppText(
                                user.phone,
                                size: 14.fSize,
                                color: AppColors.textSecondary,
                              ),
                              Gap.v(4),
                              AppText(
                                'Total Cars: ${user.carsCount}',
                                size: 13.fSize,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Gap.v(24),

                  /// 🔹 REGISTERED CARS
                  AppText(
                    'Registered Cars',
                    size: 18.fSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),

                  Gap.v(12),

                  if (user.cars.isEmpty)
                    Container(
                      padding: EdgeInsets.all(24.adaptSize),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(14.adaptSize),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.directions_car_outlined,
                              size: 48.fSize,
                              color: AppColors.textSecondary,
                            ),
                            Gap.v(12),
                            AppText(
                              'No cars registered',
                              size: 14.fSize,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...user.cars.map((car) => Padding(
                          padding: EdgeInsets.only(bottom: 12.v),
                          child: _CarStatusCard(
                            carName: car.carName,
                            plate: car.plateNumber,
                            status: car.status,
                            statusColor: car.statusColor,
                          ),
                        )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 🔹 CAR STATUS CARD
class _CarStatusCard extends StatelessWidget {
  final String carName;
  final String plate;
  final String status;
  final Color statusColor;

  const _CarStatusCard({
    required this.carName,
    required this.plate,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.adaptSize),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14.adaptSize),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.directions_car, color: statusColor),

          Gap.h(16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  carName,
                  size: 16.fSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                Gap.v(4),
                AppText(
                  plate,
                  size: 13.fSize,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),

          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 6.v),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20.adaptSize),
            ),
            child: AppText(
              status,
              size: 12.fSize,
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
