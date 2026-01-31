import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

class ChatDetailViewModel extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoUrl;

  ConversationModel? _conversation;
  List<MessageModel> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSending = false;
  StreamSubscription? _conversationSub;
  StreamSubscription? _messagesSub;

  ChatDetailViewModel({
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhotoUrl,
  });

  ConversationModel? get conversation => _conversation;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSending => _isSending;

  String? get currentUserId => _chatService.currentUserId;

  /// User can always send messages (direct chat).
  bool get canSendMessages => true;

  /// Message to show when there are no messages.
  String get emptyStateMessage => 'No messages yet. Say hi!';

  /// Whether this message was sent by the current user.
  bool isMessageFromMe(MessageModel msg) =>
      msg.senderId == _chatService.currentUserId;

  /// Formatted time string for message display (e.g. "10:24 AM").
  static String formatMessageTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final am = hour < 12;
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$h:${minute.toString().padLeft(2, '0')} ${am ? 'AM' : 'PM'}';
  }

  void initialize() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _conversationSub = _chatService.getConversationStream(conversationId).listen(
      (c) {
        _conversation = c;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        notifyListeners();
      },
    );

    _messagesSub = _chatService.getMessagesStream(conversationId).listen(
      (list) {
        _messages = list;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isSending) return;
    _isSending = true;
    notifyListeners();
    try {
      await _chatService.sendMessage(
        conversationId: conversationId,
        text: text.trim(),
      );
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isSending = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _conversationSub?.cancel();
    _messagesSub?.cancel();
    super.dispose();
  }
}
