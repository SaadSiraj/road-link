import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roadlink/core/utils/size_utils.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/shared/app_text.dart';
import '../../../viewmodels/cars_list_viewmodel.dart';
import 'car_detail_view.dart';

class CarsListView extends StatefulWidget {
  const CarsListView({super.key});

  @override
  State<CarsListView> createState() => _CarsListViewState();
}

class _CarsListViewState extends State<CarsListView> {
  final filters = ['All', 'Approved', 'Pending', 'Rejected'];

  @override
  void initState() {
    super.initState();
    // Load cars when view is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CarsListViewModel>().loadCars();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.scaffoldBackground,
        title: AppText(
          'Cars',
          size: 20.fSize,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: Consumer<CarsListViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            children: [
              /// 🔹 FILTER CHIPS
              SizedBox(
                height: 50.v,
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 16.h),
                  scrollDirection: Axis.horizontal,
                  itemCount: filters.length,
                  separatorBuilder: (_, __) => Gap.h(10),
                  itemBuilder: (context, index) {
                    final filter = filters[index];
                    final isSelected = viewModel.selectedFilter == filter;
                    final filterColor = _getFilterColor(filter);

                    return ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (_) {
                        viewModel.setFilter(filter);
                      },
                      selectedColor: filterColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.backgroundSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),

              Gap.v(12),

              /// 🔹 CARS LIST
              Expanded(
                child: _buildCarsList(viewModel),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCarsList(CarsListViewModel viewModel) {
    if (viewModel.isLoading && viewModel.allCars.isEmpty) {
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
                  viewModel.loadCars();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (viewModel.filteredCars.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 64.fSize,
              color: AppColors.textSecondary,
            ),
            Gap.v(16),
            AppText(
              viewModel.selectedFilter == 'All'
                  ? 'No Cars Found'
                  : 'No ${viewModel.selectedFilter} Cars',
              size: 18.fSize,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            Gap.v(8),
            AppText(
              'There are no cars registered yet',
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
        itemCount: viewModel.filteredCars.length,
        separatorBuilder: (_, __) => Gap.v(12),
        itemBuilder: (context, index) {
          final car = viewModel.filteredCars[index];
          return _CarCard(
            carName: car.carName,
            plate: car.plateNumber,
            owner: car.userName,
            status: car.status,
            statusColor: car.statusColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CarDetailsView(
                    userId: car.userId,
                    carId: car.carId,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Get color for filter chip based on filter name
  Color _getFilterColor(String filter) {
    switch (filter.toLowerCase()) {
      case 'all':
        return AppColors.primaryBlue;
      case 'approved':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.primaryBlue;
    }
  }
}

/// 🔹 CAR CARD
class _CarCard extends StatelessWidget {
  final String carName;
  final String plate;
  final String owner;
  final String status;
  final Color statusColor;
  final VoidCallback onTap;

  const _CarCard({
    required this.carName,
    required this.plate,
    required this.owner,
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
            Icon(Icons.directions_car, color: statusColor, size: 28.fSize),
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
                  Gap.v(4),
                  AppText(
                    'Owner: $owner',
                    size: 12.fSize,
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
