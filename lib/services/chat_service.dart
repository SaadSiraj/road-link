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
        .map((snap) => snap.docs
            .map((doc) => ConversationModel.fromFirestore(doc))
            .toList());
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
        .map((snap) =>
            snap.docs.map((d) => MessageModel.fromFirestore(d)).toList());
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

    await convRef.update({
      'lastMessageText': text.trim(),
      'lastMessageSenderId': uid,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
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

  /// Stream single conversation (e.g. for detail screen)
  Stream<ConversationModel?> getConversationStream(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .snapshots()
        .map((doc) =>
            doc.exists ? ConversationModel.fromFirestore(doc) : null);
  }

}
