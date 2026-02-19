import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roadlink/core/utils/size_utils.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/shared/app_text.dart';
import '../../../models/message_model.dart';
import '../../../services/fcm_service.dart';
import '../../../viewmodels/chat_detail_viewmodel.dart';
import 'chat_detail_args.dart';

class ChatDetailView extends StatefulWidget {
  final ChatDetailArgs? args;

  const ChatDetailView({super.key, this.args});

  @override
  State<ChatDetailView> createState() => _ChatDetailViewState();
}

class _ChatDetailViewState extends State<ChatDetailView> {
  ChatDetailViewModel? _viewModel;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.args != null) {
      FCMService.setCurrentConversationId(widget.args!.conversationId);
      _viewModel = ChatDetailViewModel(
        conversationId: widget.args!.conversationId,
        otherUserId: widget.args!.otherUserId,
        otherUserName: widget.args!.otherUserName,
        otherUserPhotoUrl: widget.args!.otherUserPhotoUrl,
      )..initialize();
      _viewModel!.addListener(_onViewModelChanged);
    }
  }

  void _onViewModelChanged() {
    if (_viewModel != null && _viewModel!.messages.length > _lastMessageCount) {
      _lastMessageCount = _viewModel!.messages.length;
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    FCMService.setCurrentConversationId(null);
    _viewModel?.removeListener(_onViewModelChanged);
    _viewModel?.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.args == null) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: Center(
          child: AppText('Invalid chat', color: AppColors.textSecondary),
        ),
      );
    }

    return ChangeNotifierProvider<ChatDetailViewModel>.value(
      value: _viewModel!,
      child: Consumer<ChatDetailViewModel>(
        builder: (context, vm, child) {
          return Scaffold(
            backgroundColor: AppColors.scaffoldBackground,
            body: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, vm),
                  Expanded(
                    child:
                        vm.isLoading && vm.messages.isEmpty
                            ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryBlue,
                              ),
                            )
                            : _buildMessagesList(context, vm),
                  ),
                  _buildInputBar(context, vm),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ChatDetailViewModel vm) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.v),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back,
              size: 24.fSize,
              color: AppColors.textPrimary,
            ),
          ),
          Gap.h(12),
          _buildAvatar(vm.otherUserPhotoUrl),
          Gap.h(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  vm.otherUserName,
                  size: 16.fSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                Gap.v(2),
                Row(
                  children: [
                    Container(
                      width: 8.adaptSize,
                      height: 8.adaptSize,
                      decoration: BoxDecoration(
                        color:
                            vm.isOnline
                                ? AppColors.success
                                : AppColors.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Gap.h(6),
                    AppText(
                      vm.getLastSeenText(),
                      size: 12.fSize,
                      color:
                          vm.isOnline
                              ? AppColors.success
                              : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // IconButton(
          //   onPressed: () {},
          //   icon: Icon(
          //     Icons.phone,
          //     size: 24.fSize,
          //     color: AppColors.textPrimary,
          //   ),
          // ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.more_vert,
              size: 24.fSize,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? photoUrl) {
    return Container(
      width: 40.adaptSize,
      height: 40.adaptSize,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: ClipOval(
        child:
            photoUrl != null && photoUrl.isNotEmpty
                ? CachedNetworkImage(
                  imageUrl: photoUrl,
                  fit: BoxFit.cover,
                  placeholder:
                      (_, __) => Container(
                        color: AppColors.cardBackground,
                        child: Icon(
                          Icons.person,
                          color: AppColors.textSecondary,
                          size: 24.fSize,
                        ),
                      ),
                  errorWidget:
                      (_, __, ___) => Container(
                        color: AppColors.cardBackground,
                        child: Icon(
                          Icons.person,
                          color: AppColors.textSecondary,
                          size: 24.fSize,
                        ),
                      ),
                )
                : Image.asset(
                  AppImages.userAvatar,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Container(
                        color: AppColors.cardBackground,
                        child: Icon(
                          Icons.person,
                          color: AppColors.textSecondary,
                          size: 24.fSize,
                        ),
                      ),
                ),
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context, ChatDetailViewModel vm) {
    if (vm.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48.adaptSize,
              color: AppColors.textSecondary,
            ),
            Gap.v(12),
            AppText(
              vm.emptyStateMessage,
              size: 14.fSize,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 16.v),
      itemCount: vm.messages.length,
      itemBuilder: (context, index) {
        final msg = vm.messages[index];
        final isMe = vm.isMessageFromMe(msg);
        return _buildMessageBubble(context, vm, msg, isMe);
      },
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    ChatDetailViewModel vm,
    MessageModel msg,
    bool isMe,
  ) {
    final isRead = vm.isMessageRead(msg);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        margin: EdgeInsets.only(bottom: 8.v),
        padding: EdgeInsets.only(
          left: 16.h,
          right:
              isMe
                  ? 12.h
                  : 16.h, // Less padding on right for timestamp/tick if me
          top: 12.v,
          bottom: 12.v,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primaryBlue : AppColors.cardBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18.adaptSize),
            topRight: Radius.circular(18.adaptSize),
            bottomRight: Radius.circular(isMe ? 4.adaptSize : 18.adaptSize),
            bottomLeft: Radius.circular(isMe ? 18.adaptSize : 4.adaptSize),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 15.fSize,
                color: isMe ? Colors.white : AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            Gap.v(4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  ChatDetailViewModel.formatMessageTime(msg.createdAt),
                  size: 10.fSize,
                  color:
                      isMe
                          ? Colors.white.withOpacity(0.7)
                          : AppColors.textSecondary.withOpacity(0.7),
                ),
                if (isMe) ...[
                  Gap.h(4),
                  Icon(
                    isRead ? Icons.done_all : Icons.check,
                    size: 16.fSize,
                    color:
                        isRead
                            ? Colors
                                .white // Use white or a distinct color for read in blue bubble
                            : Colors.white.withOpacity(0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, ChatDetailViewModel vm) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.v),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40.adaptSize,
            height: 40.adaptSize,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.add,
                size: 24.fSize,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Gap.h(12),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.h),
              decoration: BoxDecoration(
                color: AppColors.textFieldFillColor,
                borderRadius: BorderRadius.circular(24.adaptSize),
              ),
              child: TextField(
                controller: _messageController,
                enabled: vm.canSendMessages,
                decoration: InputDecoration(
                  hintText:
                      vm.canSendMessages
                          ? 'Type a message...'
                          : 'Accept the request to chat',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14.fSize,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12.v),
                ),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.fSize,
                ),
                onSubmitted:
                    vm.canSendMessages ? (_) => _sendMessage(vm) : null,
              ),
            ),
          ),
          Gap.h(12),
          Container(
            width: 40.adaptSize,
            height: 40.adaptSize,
            decoration: BoxDecoration(
              color:
                  vm.canSendMessages
                      ? AppColors.primaryBlue
                      : AppColors.textSecondary.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed:
                  vm.canSendMessages && !vm.isSending
                      ? () => _sendMessage(vm)
                      : null,
              icon:
                  vm.isSending
                      ? SizedBox(
                        width: 20.adaptSize,
                        height: 20.adaptSize,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : Icon(Icons.send, size: 20.fSize, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// UI-only: get text from field, delegate send to VM, then clear and scroll.
  void _sendMessage(ChatDetailViewModel vm) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    vm.sendMessage(text);
    _messageController.clear();
    _scrollToBottom();
  }
}
