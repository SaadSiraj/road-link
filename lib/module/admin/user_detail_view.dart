import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roadlink/core/utils/size_utils.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/shared/app_text.dart';
import '../../../viewmodels/user_detail_viewmodel.dart';
import 'car_detail_view.dart';

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
        appBar: AppBar(title: const Text('User Details')),
        body: const Center(child: Text('Invalid user ID')),
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
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    viewModel.errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                  ElevatedButton(
                    onPressed: () => viewModel.loadUserDetails(widget.userId!),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (viewModel.userDetail == null) {
            return const Center(child: Text('User not found'));
          }

          final user = viewModel.userDetail!;
          final approvedCars =
              user.cars.where((c) => c.status == 'approved').toList();
          final pendingCars =
              user.cars.where((c) => c.status == 'pending').toList();
          final rejectedCars =
              user.cars.where((c) => c.status == 'rejected').toList();

          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                /// 🔹 USER PROFILE HEADER
                Container(
                  padding: EdgeInsets.all(16.adaptSize),
                  margin: EdgeInsets.all(16.adaptSize),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(14.adaptSize),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32.adaptSize,
                        backgroundColor: AppColors.primaryBlue.withOpacity(
                          0.15,
                        ),
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

                /// 🔹 TABS
                Container(
                  color: AppColors.scaffoldBackground,
                  child: TabBar(
                    labelColor: AppColors.primaryBlue,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primaryBlue,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.fSize,
                    ),
                    tabs: [
                      Tab(text: 'Approved (${approvedCars.length})'),
                      Tab(text: 'Pending (${pendingCars.length})'),
                      Tab(text: 'Rejected (${rejectedCars.length})'),
                    ],
                  ),
                ),

                /// 🔹 TAB CONTENT
                Expanded(
                  child: TabBarView(
                    children: [
                      _CarList(cars: approvedCars, userId: user.userId),
                      _CarList(cars: pendingCars, userId: user.userId),
                      _CarList(cars: rejectedCars, userId: user.userId),
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
}

class _CarList extends StatelessWidget {
  final List<UserCar> cars;
  final String userId;

  const _CarList({required this.cars, required this.userId});

  @override
  Widget build(BuildContext context) {
    if (cars.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 48.fSize,
              color: AppColors.textSecondary,
            ),
            Gap.v(12),
            AppText(
              'No cars found',
              size: 14.fSize,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.adaptSize),
      itemCount: cars.length,
      itemBuilder: (context, index) {
        final car = cars[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 12.v),
          child: _CarStatusCard(
            carName: car.carName,
            plate: car.plateNumber,
            status: car.status,
            statusColor: car.statusColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => CarDetailsView(userId: userId, carId: car.carId),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// 🔹 CAR STATUS CARD
class _CarStatusCard extends StatelessWidget {
  final String carName;
  final String plate;
  final String status;
  final Color statusColor;
  final VoidCallback onTap;

  const _CarStatusCard({
    required this.carName,
    required this.plate,
    required this.status,
    required this.statusColor,
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
      ),
    );
  }
}
