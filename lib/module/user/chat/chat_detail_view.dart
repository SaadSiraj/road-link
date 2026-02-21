import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roadlink/core/utils/size_utils.dart';

import '../../../core/constants/app_colors.dart';
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

  /// Extracts the plate number from the first structured vehicle inquiry message.
  String _extractTitle(ChatDetailViewModel vm) {
    final firstMsg = vm.messages.isNotEmpty ? vm.messages.first.text : '';
    final plateMatch = RegExp(r'Plate:\s+([A-Z0-9]+)').firstMatch(firstMsg);
    final plate = plateMatch?.group(1);
    if (plate != null) return 'Vehicle Inquiry · $plate';
    // Fallback: try to extract from the otherUserName (set by chat list)
    if (vm.otherUserName.contains('·')) return vm.otherUserName;
    return 'Vehicle Inquiry';
  }

  Widget _buildHeader(BuildContext context, ChatDetailViewModel vm) {
    final title = _extractTitle(vm);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 10.v),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, size: 24.fSize, color: AppColors.textPrimary),
          ),
          Gap.h(4),
          // System avatar — car icon, no personal photo
          Container(
            width: 40.adaptSize,
            height: 40.adaptSize,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.25), width: 1.5),
            ),
            child: Icon(Icons.directions_car_rounded, color: AppColors.primaryBlue, size: 22.fSize),
          ),
          Gap.h(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  size: 15.fSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                Gap.v(2),
                Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 11.fSize, color: AppColors.textSecondary),
                    Gap.h(4),
                    AppText(
                      'Private vehicle conversation',
                      size: 11.fSize,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context, ChatDetailViewModel vm) {
    if (vm.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_outlined, size: 48.adaptSize, color: AppColors.textSecondary),
            Gap.v(12),
            AppText(
              'No messages yet.',
              size: 15.fSize,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            Gap.v(6),
            AppText(
              'Start the conversation about this vehicle.',
              size: 13.fSize,
              color: AppColors.textSecondary,
              align: TextAlign.center,
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
        final isSystemCard = msg.text.startsWith('📋 Vehicle Inquiry');
        if (isSystemCard) return _buildSystemCard(context, msg);
        return _buildMessageBubble(context, vm, msg, isMe);
      },
    );
  }

  /// Renders the structured vehicle report as a styled card, not a plain bubble.
  Widget _buildSystemCard(BuildContext context, MessageModel msg) {
    final lines = msg.text.split('\n').where((l) => l.trim().isNotEmpty && !l.contains('─')).toList();
    final details = lines.skip(1).toList(); // skip "📋 Vehicle Inquiry"
    final note = details.isNotEmpty ? details.removeLast() : '';

    return Container(
      margin: EdgeInsets.only(bottom: 16.v),
      padding: EdgeInsets.all(16.adaptSize),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16.adaptSize),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_car_rounded, size: 18.fSize, color: AppColors.primaryBlue),
              Gap.h(8),
              AppText('Vehicle Inquiry', size: 14.fSize, fontWeight: FontWeight.w700, color: AppColors.primaryBlue),
            ],
          ),
          Divider(color: AppColors.primaryBlue.withOpacity(0.2), height: 20),
          for (final line in details)
            Padding(
              padding: EdgeInsets.only(bottom: 4.v),
              child: Text(
                line,
                style: TextStyle(
                  fontSize: 13.fSize,
                  color: AppColors.textPrimary,
                  fontFamily: 'monospace',
                  height: 1.5,
                ),
              ),
            ),
          if (note.isNotEmpty) ...[
            Gap.v(8),
            Container(
              padding: EdgeInsets.all(10.adaptSize),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(10.adaptSize),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 13.fSize, color: AppColors.textSecondary),
                  Gap.h(6),
                  Expanded(
                    child: AppText(
                      note,
                      size: 12.fSize,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Gap.v(8),
          AppText(
            ChatDetailViewModel.formatMessageTime(msg.createdAt),
            size: 10.fSize,
            color: AppColors.textSecondary,
          ),
        ],
      ),
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
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
        margin: EdgeInsets.only(bottom: 8.v),
        padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.v),
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
                  color: isMe ? Colors.white.withOpacity(0.7) : AppColors.textSecondary.withOpacity(0.7),
                ),
                if (isMe) ...[
                  Gap.h(4),
                  Icon(
                    isRead ? Icons.done_all : Icons.check,
                    size: 16.fSize,
                    color: isRead ? Colors.white : Colors.white.withOpacity(0.7),
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
      padding: EdgeInsets.fromLTRB(16.h, 10.v, 16.h, 12.v),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.h),
              decoration: BoxDecoration(
                color: AppColors.textFieldFillColor,
                borderRadius: BorderRadius.circular(24.adaptSize),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: TextField(
                controller: _messageController,
                enabled: vm.canSendMessages,
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Message about this vehicle…',
                  hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14.fSize),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12.v),
                ),
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14.fSize),
                onSubmitted: vm.canSendMessages ? (_) => _sendMessage(vm) : null,
              ),
            ),
          ),
          Gap.h(10),
          Container(
            width: 42.adaptSize,
            height: 42.adaptSize,
            decoration: BoxDecoration(
              color: vm.canSendMessages
                  ? AppColors.primaryBlue
                  : AppColors.textSecondary.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: vm.canSendMessages && !vm.isSending ? () => _sendMessage(vm) : null,
              icon: vm.isSending
                  ? SizedBox(
                      width: 18.adaptSize,
                      height: 18.adaptSize,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(Icons.send_rounded, size: 20.fSize, color: Colors.white),
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
