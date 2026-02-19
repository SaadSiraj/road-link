import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/conversation_model.dart';
import '../models/message_model.dart';
import 'fcm_sender_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FCMSenderService _fcmSender = FCMSenderService();

  String? get currentUserId => _auth.currentUser?.uid;

  /// Deterministic conversation ID for two users (order-independent)
  static String conversationIdFor(String uid1, String uid2) {
    final list = [uid1, uid2]..sort();
    return '${list[0]}_${list[1]}';
  }

  /// Stream of conversations for the current user
  Stream<List<ConversationModel>> getConversationsStream() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((doc) => ConversationModel.fromFirestore(doc))
                  .toList(),
        );
  }

  /// Get or create a conversation with another user. Direct chat, no request flow.
  Future<ConversationModel?> getOrCreateConversation({
    required String otherUserId,
  }) async {
    final uid = currentUserId;
    if (uid == null || otherUserId == uid) return null;

    final cid = conversationIdFor(uid, otherUserId);
    final ref = _firestore.collection('conversations').doc(cid);
    final existing = await ref.get();

    if (existing.exists) {
      return ConversationModel.fromFirestore(existing);
    }

    final data = {
      'participantIds': [uid, otherUserId],
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'unreadBy': {uid: 0, otherUserId: 0},
    };
    await ref.set(data);

    final created = await ref.get();
    return created.exists ? ConversationModel.fromFirestore(created) : null;
  }

  /// Stream messages for a conversation
  Stream<List<MessageModel>> getMessagesStream(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => MessageModel.fromFirestore(d)).toList(),
        );
  }

  /// Send a text message
  Future<void> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    final uid = currentUserId;
    if (uid == null || text.trim().isEmpty) return;

    final convRef = _firestore.collection('conversations').doc(conversationId);
    final convSnap = await convRef.get();
    if (!convSnap.exists) return;

    final messagesRef = convRef.collection('messages');
    await messagesRef.add({
      'senderId': uid,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': [uid],
    });

    final participantIds =
        (convSnap.data()?['participantIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final others = participantIds.where((id) => id != uid).toList();
    final otherUid = others.isNotEmpty ? others.first : null;

    final updates = <String, dynamic>{
      'lastMessageText': text.trim(),
      'lastMessageSenderId': uid,
      'lastMessageAt': FieldValue.serverTimestamp(),
    };
    if (otherUid != null) {
      updates['unreadBy.$otherUid'] = FieldValue.increment(1);

      // Send direct FCM notification
      _sendDirectNotification(otherUid, uid, text.trim(), conversationId);
    }
    await convRef.update(updates);
  }

  Future<void> _sendDirectNotification(
    String recipientId,
    String senderId,
    String text,
    String conversationId,
  ) async {
    try {
      // 1. Get recipient FCM token
      final recipientDoc =
          await _firestore.collection('users').doc(recipientId).get();
      final recipientToken = recipientDoc.data()?['fcmToken'] as String?;
      if (recipientToken == null || recipientToken.isEmpty) return;

      // 2. Get sender profile for notification content
      final senderProfile = await getUserProfile(senderId);
      final senderName = senderProfile['name'] ?? 'Someone';
      final senderPhotoUrl = senderProfile['photoUrl'] ?? '';

      // 3. Prepare payload (consistent with what Cloud Function was sending)
      final body = text.length > 100 ? '${text.substring(0, 97)}...' : text;

      await _fcmSender.sendNotification(
        recipientToken: recipientToken,
        title: senderName,
        body: body,
        data: {
          'conversationId': conversationId,
          'otherUserId': senderId,
          'otherUserName': senderName,
          'otherUserPhotoUrl': senderPhotoUrl,
          'body': body,
          'title': senderName,
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
      );
    } catch (e) {
      print('Failed to send direct notification: $e');
    }
  }

  /// Mark conversation as read for current user (clear unread badge).
  Future<void> markConversationAsRead(String conversationId) async {
    final uid = currentUserId;
    if (uid == null) return;

    final convRef = _firestore.collection('conversations').doc(conversationId);
    await convRef.update({'unreadBy.$uid': 0});

    final messagesRef = convRef.collection('messages');
    final snap = await messagesRef.get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      final data = doc.data();
      final readBy =
          (data['readBy'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      if (!readBy.contains(uid)) {
        readBy.add(uid);
        batch.update(doc.reference, {'readBy': readBy});
      }
    }
    if (snap.docs.isNotEmpty) await batch.commit();
  }

  /// Get user profile (name, photoUrl) for display
  Future<Map<String, String?>> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    return {
      'name': data?['name'] as String?,
      'photoUrl': data?['photoUrl'] as String?,
    };
  }

  /// Stream user's online status and last seen
  Stream<Map<String, dynamic>> getUserStatusStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) {
        return {'isOnline': false, 'lastSeen': null};
      }

      final data = doc.data()!;
      return {
        'isOnline': data['isOnline'] as bool? ?? false,
        'lastSeen': data['lastSeen'] as Timestamp?,
      };
    });
  }

  /// Update current user's online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    final uid = currentUserId;
    if (uid == null) return;

    try {
      await _firestore.collection('users').doc(uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Ignore errors - this is a best-effort operation
    }
  }

  /// Set user online (call when app becomes active)
  Future<void> setUserOnline() async {
    await updateOnlineStatus(true);
  }

  /// Set user offline (call when app goes to background)
  Future<void> setUserOffline() async {
    await updateOnlineStatus(false);
  }

  /// Stream single conversation (e.g. for detail screen)
  Stream<ConversationModel?> getConversationStream(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .snapshots()
        .map((doc) => doc.exists ? ConversationModel.fromFirestore(doc) : null);
  }
}
