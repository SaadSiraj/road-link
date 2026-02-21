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

  /// Unread count for the current user; comes from conversation doc (unreadBy)
  /// and updates in real time via stream.
  final int unreadCount;

  const ChatConversationItem({
    required this.conversation,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhotoUrl,
    this.unreadCount = 0,
  });

  /// Permanent vehicle label stored in Firestore, e.g. "NBR01A · Toyota Corolla 2020"
  String? get vehicleLabel => conversation.vehicleLabel;

  /// Best title for the chat list entry.
  String get displayTitle =>
      vehicleLabel != null && vehicleLabel!.isNotEmpty
          ? vehicleLabel!
          : 'Vehicle Inquiry';
}

class ChatHomeViewModel extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<ChatConversationItem> _conversations = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _conversationsSub;

  // Cache profiles so we don't re-fetch on every Firestore emission
  final Map<String, Map<String, String?>> _profileCache = {};

  List<ChatConversationItem> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentUserId => _chatService.currentUserId;

  /// Call once from the widget. Safe to call multiple times — idempotent.
  void initialize() {
    // If already subscribed and stream is alive, do nothing.
    if (_conversationsSub != null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscribeToConversations();
  }

  void _subscribeToConversations() {
    // Cancel any stale subscription before creating a new one.
    _conversationsSub?.cancel();
    _conversationsSub = null;

    _conversationsSub = _chatService.getConversationsStream().listen(
      _onConversationsUpdated,
      onError: (e) {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
      },
      // Auto-resubscribe if the stream closes unexpectedly
      cancelOnError: false,
    );
  }

  void _onConversationsUpdated(List<ConversationModel> list) {
    final uid = _chatService.currentUserId;
    if (uid == null) {
      _conversations = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Build items immediately using cached profile data — no delay for the UI.
    final items = <ChatConversationItem>[];
    final oldByCid = {for (final i in _conversations) i.conversation.id: i};

    for (final c in list) {
      final otherId = c.otherParticipantId(uid);
      if (otherId == null) continue;

      final unreadCount = c.unreadCountFor(uid);
      final cached = oldByCid[c.id];
      final cachedProfile = _profileCache[otherId];

      items.add(
        ChatConversationItem(
          conversation: c,
          otherUserId: otherId,
          // Use cached profile name > previously loaded name > placeholder
          otherUserName: cachedProfile?['name'] ?? cached?.otherUserName ?? '…',
          otherUserPhotoUrl:
              cachedProfile?['photoUrl'] ?? cached?.otherUserPhotoUrl,
          unreadCount: unreadCount,
        ),
      );
    }

    _conversations = items;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();

    // Fetch any profiles not yet in cache in the background.
    _fetchMissingProfiles(list, uid);
  }

  Future<void> _fetchMissingProfiles(
    List<ConversationModel> list,
    String uid,
  ) async {
    // Only fetch profiles we haven't cached yet.
    final missing = list
        .map((c) => c.otherParticipantId(uid))
        .whereType<String>()
        .where((id) => !_profileCache.containsKey(id))
        .toSet()
        .toList();

    if (missing.isEmpty) return;

    final fetched = await Future.wait(
      missing.map((otherId) async {
        final p = await _chatService.getUserProfile(otherId);
        return MapEntry(otherId, p);
      }),
    );

    bool changed = false;
    for (final entry in fetched) {
      _profileCache[entry.key] = entry.value;
      changed = true;
    }

    if (!changed) return;

    // Merge new profile data into current conversation list.
    _conversations = _conversations.map((item) {
      final profile = _profileCache[item.otherUserId];
      if (profile == null) return item;

      final name =
          (profile['name']?.trim().isNotEmpty == true)
              ? profile['name']!
              : item.otherUserName;
      final photoUrl = profile['photoUrl'] ?? item.otherUserPhotoUrl;

      if (name == item.otherUserName && photoUrl == item.otherUserPhotoUrl) {
        return item; // No change — avoid unnecessary rebuilds.
      }

      return ChatConversationItem(
        conversation: item.conversation,
        otherUserId: item.otherUserId,
        otherUserName: name,
        otherUserPhotoUrl: photoUrl,
        unreadCount: item.unreadCount,
      );
    }).toList();

    notifyListeners();
  }

  /// Force a full refresh (e.g. pull-to-refresh).
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    // Re-subscribe — the first emission will clear the loading state.
    _subscribeToConversations();
  }

  @override
  void dispose() {
    _conversationsSub?.cancel();
    _conversationsSub = null;
    super.dispose();
  }
}