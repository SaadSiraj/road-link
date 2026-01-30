import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roadlink/core/utils/size_utils.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/shared/app_text.dart';
import '../../../viewmodels/users_list_viewmodel.dart';
import 'user_detail_view.dart';

class UsersListView extends StatefulWidget {
  const UsersListView({super.key});

  @override
  State<UsersListView> createState() => _UsersListViewState();
}

class _UsersListViewState extends State<UsersListView> {
  @override
  void initState() {
    super.initState();
    // Load users when view is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsersListViewModel>().loadUsers();
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
          'Users',
          size: 20.fSize,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: Consumer<UsersListViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.users.isEmpty) {
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
                        viewModel.loadUsers();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (viewModel.users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64.fSize,
                    color: AppColors.textSecondary,
                  ),
                  Gap.v(16),
                  AppText(
                    'No Users Found',
                    size: 18.fSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  Gap.v(8),
                  AppText(
                    'There are no registered users yet',
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
              itemCount: viewModel.users.length,
              separatorBuilder: (_, __) => Gap.v(12),
              itemBuilder: (context, index) {
                final user = viewModel.users[index];
                return _UserCard(
                  name: user.name,
                  contact: user.phone,
                  carsCount: user.carsCount,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserDetailsView(
                          userId: user.userId,
                        ),
                      ),
                    );
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

/// 🔹 USER CARD
class _UserCard extends StatelessWidget {
  final String name;
  final String contact;
  final int carsCount;
  final VoidCallback onTap;

  const _UserCard({
    required this.name,
    required this.contact,
    required this.carsCount,
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
            /// Avatar
            CircleAvatar(
              radius: 24.adaptSize,
              backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
              child: Icon(Icons.person, color: AppColors.primaryBlue),
            ),

            Gap.h(16),

            /// Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    name,
                    size: 16.fSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  Gap.v(4),
                  AppText(
                    contact,
                    size: 13.fSize,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),

            /// Cars Count
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 6.v),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20.adaptSize),
              ),
              child: AppText(
                '$carsCount Cars',
                size: 12.fSize,
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
