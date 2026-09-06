/// A conversation shown in the chat list (mockup page 20).
class ChatContact {
  const ChatContact({
    required this.name,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
    this.online = false,
  });

  final String name;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool online;
}

/// Who sent a message in a chat thread.
enum ChatSender { me, them }

/// A single message bubble in a chat thread (mockup page 21).
class ChatMessage {
  const ChatMessage(this.sender, this.text, this.time);

  final ChatSender sender;
  final String text;
  final String time;
}
