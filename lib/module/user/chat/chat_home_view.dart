import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roadlink/core/utils/size_utils.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/routes_name.dart';
import '../../../core/shared/app_text.dart';
import '../../../viewmodels/chat_home_viewmodel.dart';
import 'chat_detail_args.dart';

class ChatHomeView extends StatefulWidget {
  const ChatHomeView({super.key});

  @override
  State<ChatHomeView> createState() => _ChatHomeViewState();
}

class _ChatHomeViewState extends State<ChatHomeView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatHomeViewModel>().initialize();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Do NOT dispose the ViewModel — it is app-level and must stay alive
    // so the unread badge updates across tabs.
    super.dispose();
  }

  /// Re-initialize the stream when the app comes back to the foreground.
  /// This handles edge cases where the Firestore stream goes quiet after
  /// the app was backgrounded for a long time.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<ChatHomeViewModel>().initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Consumer<ChatHomeViewModel>(
          builder: (context, viewModel, _) {
            return RefreshIndicator(
              color: AppColors.primaryBlue,
              onRefresh: viewModel.refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.h,
                        vertical: 20.v,
                      ),
                      child: _buildHeader(viewModel),
                    ),
                  ),
                  if (viewModel.isLoading && viewModel.conversations.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    )
                  else if (viewModel.errorMessage != null)
                    SliverFillRemaining(
                      child: _buildErrorState(viewModel),
                    )
                  else if (viewModel.conversations.isEmpty)
                    SliverFillRemaining(
                      child: _buildEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 24.h),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == viewModel.conversations.length) {
                              return SizedBox(height: 100.v);
                            }
                            return Padding(
                              padding: EdgeInsets.only(bottom: 12.v),
                              child: _buildChatItem(
                                context: context,
                                item: viewModel.conversations[index],
                              ),
                            );
                          },
                          childCount: viewModel.conversations.length + 1,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ChatHomeViewModel viewModel) {
    final totalUnread = viewModel.conversations.fold<int>(
      0,
      (sum, item) => sum + item.unreadCount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                AppText(
                  'Messages',
                  size: 24.fSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                if (totalUnread > 0) ...[
                  Gap.h(10),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.h,
                      vertical: 3.v,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(12.adaptSize),
                    ),
                    child: AppText(
                      '$totalUnread',
                      size: 12.fSize,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            // Live indicator dot — shows when stream is active
            if (!viewModel.isLoading)
              Row(
                children: [
                  Container(
                    width: 7.adaptSize,
                    height: 7.adaptSize,
                    decoration: BoxDecoration(
                      color: Colors.green.shade400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Gap.h(5),
                  AppText(
                    'Live',
                    size: 12.fSize,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
          ],
        ),
        Gap.v(4),
        if (viewModel.conversations.isNotEmpty)
          AppText(
            '${viewModel.conversations.length} conversation${viewModel.conversations.length == 1 ? '' : 's'}',
            size: 13.fSize,
            color: AppColors.textSecondary,
          ),
        Gap.v(16),
        Divider(color: AppColors.border, thickness: 1),
        Gap.v(8),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80.adaptSize,
              height: 80.adaptSize,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 40.fSize,
                color: AppColors.primaryBlue.withOpacity(0.5),
              ),
            ),
            Gap.v(20),
            AppText(
              'No conversations yet',
              size: 18.fSize,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            Gap.v(8),
            AppText(
              'When you message a car owner or a buyer messages you, conversations will appear here.',
              size: 14.fSize,
              color: AppColors.textSecondary,
              align: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ChatHomeViewModel viewModel) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 48.fSize,
              color: AppColors.textSecondary,
            ),
            Gap.v(16),
            AppText(
              'Could not load messages',
              size: 16.fSize,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            Gap.v(8),
            AppText(
              viewModel.errorMessage ?? 'Unknown error',
              size: 13.fSize,
              color: AppColors.textSecondary,
              align: TextAlign.center,
            ),
            Gap.v(20),
            TextButton.icon(
              onPressed: viewModel.refresh,
              icon: Icon(Icons.refresh, color: AppColors.primaryBlue),
              label: AppText(
                'Try again',
                size: 14.fSize,
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem({
    required BuildContext context,
    required ChatConversationItem item,
  }) {
    final displayTitle = item.displayTitle;
    final hasUnread = item.unreadCount > 0;

    // Clean preview: strip the structured vehicle report so last real message shows
    final rawLast = item.conversation.lastMessageText ?? '';
    String preview;
    if (rawLast.contains('─────────────────')) {
      final lines = rawLast
          .split('\n')
          .where((l) => !l.contains('─') && l.trim().isNotEmpty)
          .toList();
      preview = lines.isNotEmpty ? lines.last : 'Vehicle details shared';
    } else {
      preview = rawLast.isNotEmpty ? rawLast : 'No messages yet';
    }

    final timeStr = item.conversation.lastMessageAt != null
        ? _formatTime(item.conversation.lastMessageAt!)
        : '';

    // Determine if the last message was sent by current user
    final isMyMessage =
        item.conversation.lastMessageSenderId == item.conversation.participantIds
            .firstWhere(
              (id) => id != item.otherUserId,
              orElse: () => '',
            );

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          RouteNames.chatDetail,
          arguments: ChatDetailArgs(
            conversationId: item.conversation.id,
            otherUserId: item.otherUserId,
            otherUserName: displayTitle,
            otherUserPhotoUrl: null,
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(14.adaptSize),
        decoration: BoxDecoration(
          color: hasUnread
              ? AppColors.primaryBlue.withOpacity(0.04)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16.adaptSize),
          border: Border.all(
            color: hasUnread
                ? AppColors.primaryBlue.withOpacity(0.2)
                : AppColors.border,
            width: hasUnread ? 1.5 : 1,
          ),
          boxShadow: hasUnread
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            _buildAvatar(item),
            Gap.h(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppText(
                          displayTitle,
                          size: 14.fSize,
                          fontWeight: hasUnread
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: AppColors.textPrimary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Gap.h(8),
                      AppText(
                        timeStr,
                        size: 11.fSize,
                        color: hasUnread
                            ? AppColors.primaryBlue
                            : AppColors.textSecondary,
                        fontWeight: hasUnread
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ],
                  ),
                  Gap.v(5),
                  Row(
                    children: [
                      if (isMyMessage) ...[
                        Icon(
                          Icons.done_all_rounded,
                          size: 14.fSize,
                          color: AppColors.textTertiary,
                        ),
                        Gap.h(4),
                      ],
                      Expanded(
                        child: AppText(
                          preview,
                          size: 13.fSize,
                          color: hasUnread
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          fontWeight: hasUnread
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                      if (item.unreadCount > 0) ...[
                        Gap.h(8),
                        Container(
                          constraints: BoxConstraints(minWidth: 22.adaptSize),
                          height: 22.adaptSize,
                          padding: EdgeInsets.symmetric(horizontal: 6.h),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(11.adaptSize),
                          ),
                          child: Center(
                            child: AppText(
                              item.unreadCount > 99
                                  ? '99+'
                                  : '${item.unreadCount}',
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
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(ChatConversationItem item) {
    return Stack(
      children: [
        Container(
          width: 50.adaptSize,
          height: 50.adaptSize,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.10),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primaryBlue.withOpacity(0.20),
              width: 1.5,
            ),
          ),
          child: item.otherUserPhotoUrl != null
              ? ClipOval(
                  child: Image.network(
                    item.otherUserPhotoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _carIcon(),
                  ),
                )
              : _carIcon(),
        ),
        // Online indicator (if you add status stream later, wire it here)
      ],
    );
  }

  Widget _carIcon() {
    return Icon(
      Icons.directions_car_rounded,
      color: AppColors.primaryBlue,
      size: 24.fSize,
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = today.difference(msgDate).inDays;

    final h = dateTime.hour.toString().padLeft(2, '0');
    final m = dateTime.minute.toString().padLeft(2, '0');
    final timeStr = '$h:$m';

    if (diff == 0) return timeStr;
    if (diff == 1) return 'Yesterday';
    if (diff < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dateTime.weekday - 1];
    }
    return '${dateTime.day}/${dateTime.month}';
  }
}