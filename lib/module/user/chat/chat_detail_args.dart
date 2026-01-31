/// Arguments passed when navigating to chat detail screen.
class ChatDetailArgs {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoUrl;

  const ChatDetailArgs({
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhotoUrl,
  });

  static ChatDetailArgs? fromDynamic(Object? args) {
    if (args == null) return null;
    if (args is ChatDetailArgs) return args;
    if (args is Map<String, dynamic>) {
      return ChatDetailArgs(
        conversationId: args['conversationId'] as String? ?? '',
        otherUserId: args['otherUserId'] as String? ?? '',
        otherUserName: args['otherUserName'] as String? ?? 'Unknown',
        otherUserPhotoUrl: args['otherUserPhotoUrl'] as String?,
      );
    }
    return null;
  }
}
