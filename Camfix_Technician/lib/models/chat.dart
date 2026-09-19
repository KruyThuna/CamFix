/// One message bubble in a job's chat thread, from
/// `GET/POST /api/bookings/{id}/messages`.
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
