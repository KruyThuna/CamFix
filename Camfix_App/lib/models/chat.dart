/// One conversation from `GET /api/chats` - a booking that has an assigned
/// technician. Chat is scoped per booking, so only the customer and that
/// technician can see it.
class ChatThread {
  const ChatThread({
    required this.jobId,
    required this.category,
    required this.jobStatus,
    required this.otherName,
    this.otherPhone,
    this.otherTechnicianId,
    this.lastMessage,
    this.lastMine = false,
    this.lastAt,
    this.unreadCount = 0,
  });

  final int jobId;
  final String category;
  final String jobStatus;
  final String otherName;
  final String? otherPhone;
  final int? otherTechnicianId;
  final String? lastMessage;
  final bool lastMine;
  final DateTime? lastAt;
  final int unreadCount;

  factory ChatThread.fromJson(Map<String, dynamic> j) => ChatThread(
        jobId: (j['jobId'] as num?)?.toInt() ?? 0,
        category: (j['category'] ?? '').toString(),
        jobStatus: (j['jobStatus'] ?? '').toString(),
        otherName: (j['otherName'] ?? '').toString(),
        otherPhone: j['otherPhone']?.toString(),
        otherTechnicianId: (j['otherTechnicianId'] as num?)?.toInt(),
        lastMessage: j['lastMessage']?.toString(),
        lastMine: j['lastMine'] == true,
        lastAt: _date(j['lastAt']),
        unreadCount: (j['unreadCount'] as num?)?.toInt() ?? 0,
      );
}

/// One real message in a booking's chat.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.mine,
    required this.body,
    this.createdAt,
    this.readAt,
  });

  final int id;

  /// Sent by the signed-in user (computed by the server).
  final bool mine;
  final String body;
  final DateTime? createdAt;

  /// When the other person first opened it; null = not seen yet.
  final DateTime? readAt;

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: (j['id'] as num?)?.toInt() ?? 0,
        mine: j['mine'] == true,
        body: (j['body'] ?? '').toString(),
        createdAt: _date(j['createdAt']),
        readAt: _date(j['readAt']),
      );
}

/// What `/chat-thread` needs to open a conversation.
class ChatThreadArgs {
  const ChatThreadArgs({
    required this.jobId,
    required this.name,
    this.category,
    this.phone,
    this.technicianId,
  });

  final int jobId;
  final String name;
  final String? category;
  final String? phone;
  final int? technicianId;

  factory ChatThreadArgs.fromThread(ChatThread t) => ChatThreadArgs(
        jobId: t.jobId,
        name: t.otherName,
        category: t.category,
        phone: t.otherPhone,
        technicianId: t.otherTechnicianId,
      );
}

DateTime? _date(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
