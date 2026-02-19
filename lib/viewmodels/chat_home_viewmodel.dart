import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/conversation_model.dart';
import '../services/chat_service.dart';

/// Stream that emits the latest conversation list so the UI can rebuild on every Firestore update.
class _ConversationsStream {
  final StreamController<List<ChatConversationItem>> _controller =
      StreamController<List<ChatConversationItem>>.broadcast();

  Stream<List<ChatConversationItem>> get stream => _controller.stream;

  void add(List<ChatConversationItem> items) {
    if (!_controller.isClosed) _controller.add(items);
  }

  void close() => _controller.close();
}

/// UI-friendly conversation item with other user's display info
class ChatConversationItem {
  final ConversationModel conversation;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoUrl;
  /// Unread count for the current user; comes from conversation doc (unreadBy) and updates in real time via stream.
  final int unreadCount;

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
  final _ConversationsStream _conversationsStream = _ConversationsStream();

  List<ChatConversationItem> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  /// Use this in StreamBuilder so the list (and unread badges) rebuild on every Firestore update.
  Stream<List<ChatConversationItem>> get conversationsStream => _conversationsStream.stream;

  String? get currentUserId => _chatService.currentUserId;

  void initialize() {
    if (_conversationsSub != null) return; // Already listening; keep single subscription
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Firestore snapshots(): every doc change (new message, unreadBy, lastMessage) triggers an emission.
    _conversationsSub = _chatService.getConversationsStream().listen(
      (list) {
        final uid = _chatService.currentUserId;
        if (uid == null) {
          _conversations = [];
          _isLoading = false;
          _conversationsStream.add([]);
          notifyListeners();
          return;
        }

        final oldByCid = {for (final i in _conversations) i.conversation.id: i};
        final items = <ChatConversationItem>[];
        for (final c in list) {
          final otherId = c.otherParticipantId(uid);
          if (otherId == null) continue;
          final unreadCount = c.unreadCountFor(uid);
          final cached = oldByCid[c.id];
          items.add(
            ChatConversationItem(
              conversation: c,
              otherUserId: otherId,
              otherUserName: cached?.otherUserName ?? '…',
              otherUserPhotoUrl: cached?.otherUserPhotoUrl,
              unreadCount: unreadCount,
            ),
          );
        }
        _conversations = items;
        _isLoading = false;
        _errorMessage = null;
        _conversationsStream.add(items); // Drives StreamBuilder → badge updates in real time
        notifyListeners();

        _fetchProfilesThenUpdate(list, uid);
      },
      onError: (e) {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> _fetchProfilesThenUpdate(
    List<ConversationModel> list,
    String uid,
  ) async {
    final profiles = await Future.wait([
      for (final c in list)
        (() async {
          final otherId = c.otherParticipantId(uid);
          if (otherId == null) return <String, dynamic>{};
          final p = await _chatService.getUserProfile(otherId);
          return <String, dynamic>{
            'id': otherId,
            'name': p['name'],
            'photoUrl': p['photoUrl'],
          };
        })(),
    ]);
    final profileById = <String, Map<String, dynamic>>{};
    for (final p in profiles) {
      final id = p['id'] as String?;
      if (id != null) profileById[id] = p;
    }
    // Merge names/photos into current list so we never overwrite newer unread counts
    final current = _conversations;
    final merged = <ChatConversationItem>[];
    for (final i in current) {
      final p = profileById[i.otherUserId];
      final name =
          p?['name']?.trim().isNotEmpty == true ? p!['name']! : i.otherUserName;
      final photoUrl = p?['photoUrl'] ?? i.otherUserPhotoUrl;
      merged.add(
        ChatConversationItem(
          conversation: i.conversation,
          otherUserId: i.otherUserId,
          otherUserName: name,
          otherUserPhotoUrl: photoUrl,
          unreadCount: i.unreadCount,
        ),
      );
    }
    _conversations = merged;
    _conversationsStream.add(merged); // Keep StreamBuilder in sync after profile merge
    notifyListeners();
  }

  @override
  void dispose() {
    _conversationsSub?.cancel();
    _conversationsSub = null;
    _conversationsStream.close();
    super.dispose();
  }
}
