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
            return const Center(child: CircularProgressIndicator());
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
                  onEdit: () {
                    _showEditUserDialog(context, viewModel, user);
                  },
                  onDelete: () {
                    _showDeleteUserDialog(context, viewModel, user);
                  },
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserDetailsView(userId: user.userId),
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

  void _showEditUserDialog(
    BuildContext context,
    UsersListViewModel viewModel,
    UserListItem user,
  ) {
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone);

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: AppText(
              'Edit User',
              size: 18.fSize,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primaryBlue),
                    ),
                  ),
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                Gap.v(12),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primaryBlue),
                    ),
                  ),
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: AppText('Cancel', color: AppColors.textSecondary),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final success = await viewModel.updateUser(
                    userId: user.userId,
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'User updated successfully'
                              : 'Failed to update user',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
                child: AppText(
                  'Save',
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
    );
  }

  void _showDeleteUserDialog(
    BuildContext context,
    UsersListViewModel viewModel,
    UserListItem user,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: AppText(
              'Delete User',
              size: 18.fSize,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            content: AppText(
              'Are you sure you want to delete ${user.name}? This action cannot be undone and will delete all their registered cars.',
              color: AppColors.textSecondary,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: AppText('Cancel', color: AppColors.textSecondary),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final success = await viewModel.deleteUser(user.userId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'User deleted successfully'
                              : 'Failed to delete user',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
                child: AppText(
                  'Delete',
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({
    required this.name,
    required this.contact,
    required this.carsCount,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
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
              padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 4.v),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.adaptSize),
              ),
              child: AppText(
                '${carsCount} Cars',
                size: 11.fSize,
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),

            Gap.h(12),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edit Button
                InkWell(
                  onTap: onEdit,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.edit,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                Gap.h(8),

                // Delete Button
                InkWell(
                  onTap: onDelete,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(Icons.delete, size: 20, color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
