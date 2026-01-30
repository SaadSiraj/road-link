import 'package:flutter/material.dart';
import 'package:roadlink/core/utils/size_utils.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/shared/app_text.dart';
import 'chat_detail_view.dart';

class ChatHomeView extends StatelessWidget {
  const ChatHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.h, vertical: 24.v),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔹 TOP HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    /// App Name
                    AppText(
                      'Car',
                      size: 24.fSize,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),

                    /// Right side icons
                    Row(
                      children: [
                        /// Notification Bell with Badge
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: Icon(
                                Icons.notifications_outlined,
                                size: 24.fSize,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                width: 18.adaptSize,
                                height: 18.adaptSize,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B35), // Orange
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: AppText(
                                    '3',
                                    size: 10.fSize,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        Gap.h(12),

                        /// Profile Picture
                        Container(
                          width: 40.adaptSize,
                          height: 40.adaptSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.border,
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              AppImages.userAvatar,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.cardBackground,
                                  child: Icon(
                                    Icons.person,
                                    color: AppColors.textSecondary,
                                    size: 24.fSize,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Divider(color: AppColors.border, thickness: 1),
                Gap.v(32),

                /// 🔹 NEW CHAT REQUESTS CARD
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.adaptSize),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16.adaptSize),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(
                        'New Chat Requests',
                        size: 16.fSize,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      Container(
                        width: 28.adaptSize,
                        height: 28.adaptSize,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: AppText(
                            '2',
                            size: 14.fSize,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Gap.v(24),

                /// 🔹 CHAT LIST
                Column(
                  children: [
                    _buildChatItem(
                      context: context,
                      name: 'John Ham',
                      message: 'I found that mechanic you ....',
                      time: '10:30 AM',
                      unreadCount: 2,
                    ),
                    Gap.v(16),
                    _buildChatItem(
                      context: context,
                      name: 'John Ham',
                      message: 'I found that mechanic you ....',
                      time: '10:30 AM',
                      unreadCount: 0,
                    ),
                    Gap.v(16),
                    _buildChatItem(
                      context: context,
                      name: 'John Ham',
                      message: 'I found that mechanic you ....',
                      time: '10:30 AM',
                      unreadCount: 0,
                    ),
                  ],
                ),

                Gap.v(100), // Bottom padding for navigation bar
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Helper method to build chat item
  Widget _buildChatItem({
    required BuildContext context,
    required String name,
    required String message,
    required String time,
    required int unreadCount,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatDetailView(
                  userName: name,
                  isOnline: true,
                  isRequest: unreadCount > 0,
                ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16.adaptSize),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14.adaptSize),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            /// Profile Picture
            Container(
              width: 50.adaptSize,
              height: 50.adaptSize,
              decoration: BoxDecoration(shape: BoxShape.circle),
              child: ClipOval(
                child: Image.asset(
                  AppImages.userAvatar,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.scaffoldBackground,
                      child: Icon(
                        Icons.person,
                        color: AppColors.textSecondary,
                        size: 28.fSize,
                      ),
                    );
                  },
                ),
              ),
            ),

            Gap.h(16),

            /// Chat Info
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
                    message,
                    size: 14.fSize,
                    color: AppColors.textSecondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            Gap.h(12),

            /// Time and Unread Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AppText(time, size: 12.fSize, color: AppColors.textSecondary),
                if (unreadCount > 0) ...[
                  Gap.v(8),
                  Container(
                    width: 20.adaptSize,
                    height: 20.adaptSize,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: AppText(
                        unreadCount.toString(),
                        size: 11.fSize,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
