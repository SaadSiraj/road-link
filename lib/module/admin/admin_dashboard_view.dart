import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:roadlink/core/utils/size_utils.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/shared/app_text.dart';
import '../../core/shared/admin_drawer.dart';
import '../../../viewmodels/admin_dashboard_viewmodel.dart';
import '../../core/shared/app_appbar.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  @override
  void initState() {
    super.initState();
    // Load dashboard data when view is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminDashboardViewModel>().loadDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        centerTitle: true,
        showBackButton: false,
        title: 'Admin Dashboard',
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
        ),
      ),
      drawer: AdminDrawer(),
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await context.read<AdminDashboardViewModel>().refresh();
          },
          color: AppColors.primaryBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 24.h, vertical: 24.v),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔹 HEADER
                AppText(
                  'Dashboard Overview',
                  size: 20.fSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),

                Gap.v(16),

                /// 🔹 FILTER CHIPS
                Consumer<AdminDashboardViewModel>(
                  builder: (context, viewModel, _) {
                    return SizedBox(
                      height: 40.v,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: viewModel.filters.length,
                        separatorBuilder: (_, __) => Gap.h(10),
                        itemBuilder: (context, index) {
                          final filter = viewModel.filters[index];
                          final isSelected = viewModel.selectedFilter == filter;

                          return ChoiceChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (_) => viewModel.setFilter(filter),
                            selectedColor: AppColors.primaryBlue,
                            backgroundColor: AppColors.cardBackground,
                            labelStyle: TextStyle(
                              color:
                                  isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                Gap.v(24),

                /// 🔹 STATS GRID
                Consumer<AdminDashboardViewModel>(
                  builder: (context, viewModel, child) {
                    if (viewModel.isLoading && viewModel.totalUsers == 0) {
                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.1,
                        children: List.generate(
                          5,
                          (index) => _ShimmerStatCard(),
                        ),
                      );
                    }

                    if (viewModel.errorMessage != null) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48.fSize,
                            ),
                            Gap.v(8),
                            AppText(
                              viewModel.errorMessage!,
                              size: 14.fSize,
                              color: Colors.red,
                              align: TextAlign.center,
                            ),
                            Gap.v(16),
                            ElevatedButton(
                              onPressed: () {
                                viewModel.loadDashboardStats();
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.1,
                      children: [
                        _StatCard(
                          title: 'Total Users',
                          value: viewModel.totalUsers.toString(),
                          icon: Icons.people,
                          color: AppColors.primaryBlue,
                        ),
                        _StatCard(
                          title: 'Total Cars',
                          value: viewModel.totalCars.toString(),
                          icon: Icons.directions_car,
                          color: AppColors.success,
                        ),
                        _StatCard(
                          title: 'Pending Requests',
                          value: viewModel.pendingRequests.toString(),
                          icon: Icons.pending_actions,
                          color: Colors.orange,
                        ),
                        _StatCard(
                          title: 'Approved Cars',
                          value: viewModel.approvedCars.toString(),
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                        _StatCard(
                          title: 'Rejected Cars',
                          value: viewModel.rejectedCars.toString(),
                          icon: Icons.cancel,
                          color: Colors.red,
                        ),
                      ],
                    );
                  },
                ),

                Gap.v(32),

                /// 🔹 QUICK ACTIONS
                // AppText(
                //   'Quick Actions',
                //   size: 20.fSize,
                //   fontWeight: FontWeight.bold,
                //   color: AppColors.textPrimary,
                // ),

                // Gap.v(16),

                // _ActionTile(
                //   title: 'View Pending Requests',
                //   subtitle: 'Approve or reject car registrations',
                //   icon: Icons.pending_actions,
                //   onTap: () {},
                // ),

                // Gap.v(12),

                // _ActionTile(
                //   title: 'Go to Users',
                //   subtitle: 'Manage registered users',
                //   icon: Icons.people_outline,
                //   onTap: () {},
                // ),

                // Gap.v(12),

                // _ActionTile(
                //   title: 'Go to Cars',
                //   subtitle: 'View all registered cars',
                //   icon: Icons.directions_car_filled,
                //   onTap: () {},
                // ),

                // Gap.v(40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 🔹 STAT CARD
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.adaptSize),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.adaptSize),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.25), color.withOpacity(0.05)],
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28.fSize),
          const Spacer(),
          AppText(
            value,
            size: 28.fSize,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          Gap.v(4),
          AppText(title, size: 14.fSize, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

/// 🔹 SHIMMER STAT CARD
class _ShimmerStatCard extends StatelessWidget {
  const _ShimmerStatCard();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardBackground,
      highlightColor: AppColors.border,
      period: const Duration(milliseconds: 1500),
      child: Container(
        padding: EdgeInsets.all(20.adaptSize),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.adaptSize),
          color: AppColors.cardBackground,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28.fSize,
              height: 28.fSize,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const Spacer(),
            Container(
              width: 60.adaptSize,
              height: 28.fSize,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Gap.v(8),
            Container(
              width: 80.adaptSize,
              height: 14.fSize,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔹 ACTION TILE
class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14.adaptSize),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.adaptSize),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14.adaptSize),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44.adaptSize,
              height: 44.adaptSize,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.adaptSize),
              ),
              child: Icon(icon, color: AppColors.primaryBlue),
            ),
            Gap.h(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    title,
                    size: 16.fSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  Gap.v(4),
                  AppText(
                    subtitle,
                    size: 13.fSize,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16.fSize,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
