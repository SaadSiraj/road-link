import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roadlink/core/utils/size_utils.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/routes/routes_name.dart';
import '../../../core/shared/app_text.dart';
import '../../../viewmodels/chat_home_viewmodel.dart';
import 'chat_detail_args.dart';

class ChatHomeView extends StatefulWidget {
  const ChatHomeView({super.key});

  @override
  State<ChatHomeView> createState() => _ChatHomeViewState();
}

class _ChatHomeViewState extends State<ChatHomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatHomeViewModel>().initialize();
    });
  }

  @override
  void dispose() {
    context.read<ChatHomeViewModel>().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Consumer<ChatHomeViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading && viewModel.conversations.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryBlue),
              );
            }

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.h, vertical: 24.v),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText(
                          'Chat',
                          size: 24.fSize,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: Icon(
                                Icons.notifications_outlined,
                                size: 24.fSize,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Gap.h(12),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, RouteNames.profile);
                              },
                              child: Container(
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
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.person,
                                      color: AppColors.textSecondary,
                                      size: 24.fSize,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Divider(color: AppColors.border, thickness: 1),
                    Gap.v(32),

                    /// Chat list or empty state
                    if (viewModel.conversations.isEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 48.v),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64.adaptSize,
                                color: AppColors.textSecondary,
                              ),
                              Gap.v(16),
                              AppText(
                                'No conversations yet',
                                size: 16.fSize,
                                color: AppColors.textSecondary,
                              ),
                              Gap.v(8),
                              AppText(
                                'Start a chat from the dashboard when you find a car or user.',
                                size: 14.fSize,
                                color: AppColors.textTertiary,
                                align: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        children: viewModel.conversations
                            .map((item) => Padding(
                                  padding: EdgeInsets.only(bottom: 16.v),
                                  child: _buildChatItem(
                                    context: context,
                                    item: item,
                                  ),
                                ))
                            .toList(),
                      ),

                    Gap.v(100),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChatItem({
    required BuildContext context,
    required ChatConversationItem item,
  }) {
    final lastMsg = item.conversation.lastMessageText ?? 'No messages yet';
    final timeStr = item.conversation.lastMessageAt != null
        ? _formatTime(item.conversation.lastMessageAt!)
        : '';

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          RouteNames.chatDetail,
          arguments: ChatDetailArgs(
            conversationId: item.conversation.id,
            otherUserId: item.otherUserId,
            otherUserName: item.otherUserName,
            otherUserPhotoUrl: item.otherUserPhotoUrl,
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
            _buildAvatar(item.otherUserPhotoUrl),
            Gap.h(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    item.otherUserName,
                    size: 16.fSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  Gap.v(4),
                  AppText(
                    lastMsg,
                    size: 14.fSize,
                    color: AppColors.textSecondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Gap.h(12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AppText(
                  timeStr,
                  size: 12.fSize,
                  color: AppColors.textSecondary,
                ),
                if (item.unreadCount > 0) ...[
                  Gap.v(8),
                  Container(
                    width: 20.adaptSize,
                    height: 20.adaptSize,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: AppText(
                        '${item.unreadCount}',
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

  Widget _buildAvatar(String? photoUrl) {
    return Container(
      width: 50.adaptSize,
      height: 50.adaptSize,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: ClipOval(
        child: photoUrl != null && photoUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppColors.scaffoldBackground,
                  child: Icon(
                    Icons.person,
                    color: AppColors.textSecondary,
                    size: 28.fSize,
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.scaffoldBackground,
                  child: Icon(
                    Icons.person,
                    color: AppColors.textSecondary,
                    size: 28.fSize,
                  ),
                ),
              )
            : Image.asset(
                AppImages.userAvatar,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.scaffoldBackground,
                  child: Icon(
                    Icons.person,
                    color: AppColors.textSecondary,
                    size: 28.fSize,
                  ),
                ),
              ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );
    final diff = today.difference(msgDate).inDays;
    final timeStr =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    if (diff == 0) return timeStr;
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '${dateTime.weekday == 1 ? 'Mon' : dateTime.weekday == 2 ? 'Tue' : dateTime.weekday == 3 ? 'Wed' : dateTime.weekday == 4 ? 'Thu' : dateTime.weekday == 5 ? 'Fri' : dateTime.weekday == 6 ? 'Sat' : 'Sun'}';
    return '${dateTime.day}/${dateTime.month}';
  }
}
