import '../models/chat.dart';
import 'api_client.dart';

/// Real per-booking chat with the assigned technician (`/api/chats`).
class ChatApi {
  ChatApi._();
  static final ChatApi instance = ChatApi._();

  final _client = ApiClient.instance;

  Future<List<ChatThread>> threads() async {
    final raw = await _client.getJsonList('/api/chats');
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ChatThread.fromJson)
        .toList();
  }

  /// All messages, or only those newer than [afterId]. Loading a thread
  /// marks the other side's messages as read.
  Future<List<ChatMessage>> messages(int jobId, {int? afterId}) async {
    final q = afterId == null ? '' : '?after=$afterId';
    final raw = await _client.getJsonList('/api/chats/$jobId/messages$q');
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ChatMessage.fromJson)
        .toList();
  }

  Future<ChatMessage> send(int jobId, String body) async {
    final json = await _client.postJson(
      '/api/chats/$jobId/messages',
      {'body': body},
      withAuth: true,
    );
    return ChatMessage.fromJson(json);
  }
}
