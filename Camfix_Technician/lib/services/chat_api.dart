import '../models/chat_message.dart';
import 'api_client.dart';

/// Real per-job chat with the customer (`/api/chats`), shared with the
/// customer app - the server works out which side the caller is on.
class ChatApi {
  ChatApi._();
  static final ChatApi instance = ChatApi._();

  final _client = ApiClient.instance;

  Future<List<ChatThreadSummary>> threads() async {
    final raw = await _client.getJsonList('/api/chats');
    return raw.map(ChatThreadSummary.fromJson).toList();
  }

  /// Loading marks the customer's messages as read.
  Future<List<ChatMessage>> messages(int jobId) async {
    final raw = await _client.getJsonList('/api/chats/$jobId/messages');
    return raw.map(ChatMessage.fromJson).toList();
  }

  Future<ChatMessage> send(int jobId, String body) async {
    final json = await _client.postJson('/api/chats/$jobId/messages', {
      'body': body,
    }, withAuth: true);
    return ChatMessage.fromJson(json);
  }
}
