import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final List<String> readBy;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.readBy = const [],
  });

  bool get isFromMe => false; // Caller sets by comparing senderId to currentUser

  factory MessageModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final createdAt = data['createdAt'] as Timestamp?;
    final readBy = (data['readBy'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ?? [];

    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: createdAt?.toDate() ?? DateTime.now(),
      readBy: readBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'readBy': readBy,
    };
  }
}
