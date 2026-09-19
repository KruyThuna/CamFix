/// One of the customer's chat conversations, from `GET /api/chats/mine` - one
/// per booking that has an assigned technician.
class ChatThread {
  const ChatThread({
    required this.jobId,
    required this.otherPartyName,
    required this.category,
    required this.status,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageMine = false,
  });

  final int jobId;
  final String otherPartyName;
  final String category;
  final String status;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final bool lastMessageMine;

  factory ChatThread.fromJson(Map<String, dynamic> j) => ChatThread(
        jobId: (j['jobId'] as num).toInt(),
        otherPartyName: j['otherPartyName']?.toString() ?? '',
        category: j['category']?.toString() ?? '',
        status: j['status']?.toString() ?? '',
        lastMessage: j['lastMessage']?.toString(),
        lastMessageAt: j['lastMessageAt'] == null
            ? null
            : DateTime.tryParse(j['lastMessageAt'].toString())?.toLocal(),
        lastMessageMine: j['lastMessageMine'] == true,
      );
}

/// One message bubble in a chat thread, from `GET/POST /api/bookings/{id}/messages`.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.jobId,
    required this.senderUserId,
    required this.mine,
    required this.text,
    required this.createdAt,
    this.senderName,
  });

  final int id;
  final int jobId;
  final int senderUserId;
  final String? senderName;
  final bool mine;
  final String text;
  final DateTime createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: (j['id'] as num).toInt(),
        jobId: (j['jobId'] as num).toInt(),
        senderUserId: (j['senderUserId'] as num).toInt(),
        senderName: j['senderName']?.toString(),
        mine: j['mine'] == true,
        text: j['text']?.toString() ?? '',
        createdAt:
            DateTime.tryParse(j['createdAt']?.toString() ?? '')?.toLocal() ??
                DateTime.now(),
      );
}
