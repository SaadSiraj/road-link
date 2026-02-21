import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/conversation_model.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
  /// [vehicleLabel] is stored permanently in the doc (e.g. "NBR01A · Toyota Corolla 2020")
  /// so the chat list always shows the right vehicle, regardless of later messages.
  Future<ConversationModel?> getOrCreateConversation({
    required String otherUserId,
    String? vehicleLabel,
  }) async {
    final uid = currentUserId;
    if (uid == null || otherUserId == uid) return null;

    final cid = conversationIdFor(uid, otherUserId);
    final ref = _firestore.collection('conversations').doc(cid);
    final existing = await ref.get();

    if (existing.exists) {
      // If a label is provided and the doc doesn't have one yet, write it now.
      if (vehicleLabel != null && existing.data()?['vehicleLabel'] == null) {
        await ref.update({'vehicleLabel': vehicleLabel});
      }
      final refreshed = await ref.get();
      return ConversationModel.fromFirestore(refreshed);
    }

    final data = <String, dynamic>{
      'participantIds': [uid, otherUserId],
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'unreadBy': {uid: 0, otherUserId: 0},
      if (vehicleLabel != null) 'vehicleLabel': vehicleLabel,
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
      // Notification is sent by the Cloud Function (functions/index.js) — no duplicate send here.
    }
    await convRef.update(updates);
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
