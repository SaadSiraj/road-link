import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

class ChatDetailViewModel extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final String conversationId;
  final String otherUserId;
  String _otherUserName;
  String? _otherUserPhotoUrl;

  ConversationModel? _conversation;
  List<MessageModel> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSending = false;
  bool _isOnline = false;
  DateTime? _lastSeen;
  StreamSubscription? _conversationSub;
  StreamSubscription? _messagesSub;
  StreamSubscription? _userStatusSub;

  ChatDetailViewModel({
    required this.conversationId,
    required this.otherUserId,
    required String otherUserName,
    String? otherUserPhotoUrl,
  }) : _otherUserName = otherUserName,
       _otherUserPhotoUrl = otherUserPhotoUrl;

  ConversationModel? get conversation => _conversation;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSending => _isSending;
  bool get isOnline => _isOnline;
  DateTime? get lastSeen => _lastSeen;
  String get otherUserName => _otherUserName;
  String? get otherUserPhotoUrl => _otherUserPhotoUrl;

  String? get currentUserId => _chatService.currentUserId;

  /// User can always send messages (direct chat).
  bool get canSendMessages => true;

  /// Message to show when there are no messages.
  String get emptyStateMessage => 'No messages yet. Say hi!';

  /// Format last seen time
  String getLastSeenText() {
    if (_isOnline) return 'Online';
    if (_lastSeen == null) return 'Offline';

    final now = DateTime.now();
    final difference = now.difference(_lastSeen!);

    if (difference.inMinutes < 1) {
      return 'Last seen just now';
    } else if (difference.inMinutes < 60) {
      return 'Last seen ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Last seen ${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Last seen yesterday';
    } else if (difference.inDays < 7) {
      return 'Last seen ${difference.inDays}d ago';
    } else {
      return 'Last seen ${formatMessageTime(_lastSeen!)}';
    }
  }

  /// Whether this message was sent by the current user.
  bool isMessageFromMe(MessageModel msg) =>
      msg.senderId == _chatService.currentUserId;

  /// Check if message is read by the other user
  bool isMessageRead(MessageModel msg) {
    if (msg.readBy.contains(otherUserId)) return true;
    return false;
  }

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

    // Mark as read so chat list badge clears
    _chatService.markConversationAsRead(conversationId);

    // Listen to conversation updates
    _conversationSub = _chatService
        .getConversationStream(conversationId)
        .listen(
          (c) {
            _conversation = c;
            notifyListeners();
          },
          onError: (e) {
            _errorMessage = e.toString();
            notifyListeners();
          },
        );

    // Listen to messages
    _messagesSub = _chatService
        .getMessagesStream(conversationId)
        .listen(
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

    // Listen to user status (online/offline)
    _userStatusSub = _chatService
        .getUserStatusStream(otherUserId)
        .listen(
          (status) {
            _isOnline = status['isOnline'] as bool? ?? false;
            final lastSeenTimestamp = status['lastSeen'] as Timestamp?;
            _lastSeen = lastSeenTimestamp?.toDate();
            notifyListeners();
          },
          onError: (e) {
            // Ignore status errors - not critical
          },
        );

    // Fetch updated user profile (in case name/photo changed)
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final profile = await _chatService.getUserProfile(otherUserId);
      if (profile['name'] != null) {
        _otherUserName = profile['name']!;
      }
      if (profile['photoUrl'] != null) {
        _otherUserPhotoUrl = profile['photoUrl'];
      }
      notifyListeners();
    } catch (e) {
      // Keep the existing name/photo if fetch fails
    }
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
    _userStatusSub?.cancel();
    super.dispose();
  }
}
