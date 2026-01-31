import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/conversation_model.dart';
import '../services/chat_service.dart';

/// UI-friendly conversation item with other user's display info
class ChatConversationItem {
  final ConversationModel conversation;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoUrl;
  final int unreadCount; // placeholder for future unread

  const ChatConversationItem({
    required this.conversation,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhotoUrl,
    this.unreadCount = 0,
  });
}

class ChatHomeViewModel extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<ChatConversationItem> _conversations = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _conversationsSub;

  List<ChatConversationItem> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get currentUserId => _chatService.currentUserId;

  void initialize() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _conversationsSub?.cancel();

    _conversationsSub = _chatService.getConversationsStream().listen(
      (list) async {
        final uid = _chatService.currentUserId;
        if (uid == null) {
          _conversations = [];
          _isLoading = false;
          notifyListeners();
          return;
        }

        final items = <ChatConversationItem>[];
        for (final c in list) {
          final otherId = c.otherParticipantId(uid);
          if (otherId == null) continue;
          final profile = await _chatService.getUserProfile(otherId);
          items.add(ChatConversationItem(
            conversation: c,
            otherUserId: otherId,
            otherUserName: profile['name']?.trim().isNotEmpty == true
                ? profile['name']!
                : 'Unknown',
            otherUserPhotoUrl: profile['photoUrl'],
            unreadCount: 0,
          ));
        }
        _conversations = items;
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

  @override
  void dispose() {
    _conversationsSub?.cancel();
    super.dispose();
  }
}
