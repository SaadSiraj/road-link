import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a chat conversation between two users.
/// Supports "chat request" flow: pending until the other user accepts.
class ConversationModel {
  final String id;
  final List<String> participantIds;
  final String? lastMessageText;
  final String? lastMessageSenderId;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  /// pending = chat request not yet accepted; accepted = normal chat
  final String status;
  final String? requestedBy;

  const ConversationModel({
    required this.id,
    required this.participantIds,
    this.lastMessageText,
    this.lastMessageSenderId,
    this.lastMessageAt,
    this.createdAt,
    this.status = 'accepted',
    this.requestedBy,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';

  /// The other participant's uid (for current user)
  String? otherParticipantId(String currentUserId) {
    if (participantIds.length != 2) return null;
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => participantIds.first,
    );
  }

  factory ConversationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final lastMessageAt = data['lastMessageAt'] as Timestamp?;
    final createdAt = data['createdAt'] as Timestamp?;
    final participantIds = (data['participantIds'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ?? [];

    return ConversationModel(
      id: doc.id,
      participantIds: participantIds,
      lastMessageText: data['lastMessageText'] as String?,
      lastMessageSenderId: data['lastMessageSenderId'] as String?,
      lastMessageAt: lastMessageAt?.toDate(),
      createdAt: createdAt?.toDate(),
      status: data['status'] as String? ?? 'accepted',
      requestedBy: data['requestedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participantIds': participantIds,
      'lastMessageText': lastMessageText,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageAt': lastMessageAt != null
          ? Timestamp.fromDate(lastMessageAt!)
          : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'status': status,
      'requestedBy': requestedBy,
    };
  }
}
