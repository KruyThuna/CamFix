import '../models/chat.dart';
import 'api_client.dart';

/// Per-booking chat (`/api/chats/**`, `/api/bookings/{id}/messages`).
class ChatApi {
  ChatApi._();
  static final ChatApi instance = ChatApi._();

  final _client = ApiClient.instance;

  Future<List<ChatThread>> myThreads() async {
    final raw = await _client.getJsonList('/api/chats/mine');
    return raw.whereType<Map<String, dynamic>>().map(ChatThread.fromJson).toList();
  }

  Future<List<ChatMessage>> messages(int jobId) async {
    final raw = await _client.getJsonList('/api/bookings/$jobId/messages');
    return raw.whereType<Map<String, dynamic>>().map(ChatMessage.fromJson).toList();
  }

  Future<ChatMessage> send(int jobId, String text) async {
    final json = await _client.postJson(
        '/api/bookings/$jobId/messages', {'text': text},
        withAuth: true);
    return ChatMessage.fromJson(json);
  }
}
