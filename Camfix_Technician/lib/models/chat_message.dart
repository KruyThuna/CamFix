/// One message in a job's chat with the customer (`/api/chats/{jobId}`).
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.mine,
    required this.body,
    this.createdAt,
    this.readAt,
  });

  final int id;

  /// Sent by this technician (computed by the server).
  final bool mine;
  final String body;
  final DateTime? createdAt;

  /// When the customer first opened it; null = not seen yet.
  final DateTime? readAt;

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: (j['id'] as num?)?.toInt() ?? 0,
    mine: j['mine'] == true,
    body: (j['body'] ?? '').toString(),
    createdAt: _date(j['createdAt']),
    readAt: _date(j['readAt']),
  );
}

/// Unread count per job, from `GET /api/chats`.
class ChatThreadSummary {
  const ChatThreadSummary({required this.jobId, required this.unreadCount});

  final int jobId;
  final int unreadCount;

  factory ChatThreadSummary.fromJson(Map<String, dynamic> j) =>
      ChatThreadSummary(
        jobId: (j['jobId'] as num?)?.toInt() ?? 0,
        unreadCount: (j['unreadCount'] as num?)?.toInt() ?? 0,
      );
}

DateTime? _date(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
