import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/chat.dart';
import '../theme/app_theme.dart';

/// Chat thread (mockup page 21): header with the contact, a day divider,
/// incoming / outgoing message bubbles and a composer.
class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({super.key});

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  static const Color _green = Color(0xFF2ECC71);
  static const ChatContact _fallback = ChatContact(
    name: 'Vanna Sok',
    lastMessage: "Hey, What's up",
    time: '12:17 PM',
    online: true,
  );

  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  final List<ChatMessage> _messages = [
    const ChatMessage(ChatSender.them, 'Hello', '2:15 PM'),
    const ChatMessage(ChatSender.me, "Hey, What's up", '2:17 PM'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(
        ChatSender.me,
        text,
        TimeOfDay.now().format(context),
      ));
      _controller.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final contact =
        ModalRoute.of(context)?.settings.arguments as ChatContact? ?? _fallback;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(contact),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                children: [
                  _dayDivider(AppStrings.t('today')),
                  const SizedBox(height: 8),
                  ..._messages.map(_messageRow),
                ],
              ),
            ),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ChatContact c) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
      decoration: BoxDecoration(
        color: p.surface,
        boxShadow: [
          BoxShadow(color: p.shadow, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            },
            icon: Icon(Icons.arrow_back, color: p.textPrimary, size: 22),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: p.surfaceAlt,
            child: const Icon(Icons.person,
                color: AppColors.primaryBlue, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary)),
                Text(
                  c.online ? AppStrings.t('online') : AppStrings.t('offline'),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: c.online ? _green : p.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _snack('${AppStrings.t('calling')} ${c.name}…'),
            icon: const Icon(Icons.call_outlined,
                color: AppColors.primaryBlue, size: 20),
          ),
          IconButton(
            onPressed: () => _snack(AppStrings.t('chatOptions')),
            icon: Icon(Icons.more_vert, color: p.textPrimary, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _dayDivider(String label) {
    final p = context.pal;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: p.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: p.textSecondary),
        ),
      ),
    );
  }

  Widget _messageRow(ChatMessage m) {
    final p = context.pal;
    final bool mine = m.sender == ChatSender.me;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment:
            mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: mine ? AppColors.primaryBlue : p.surfaceAlt,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(mine ? 16 : 4),
                bottomRight: Radius.circular(mine ? 4 : 16),
              ),
            ),
            child: Text(
              m.text,
              style: TextStyle(
                fontSize: 14,
                color: mine ? AppColors.white : p.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(m.time,
              style: TextStyle(fontSize: 10.5, color: p.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: p.surface,
        boxShadow: [
          BoxShadow(
              color: p.shadow, blurRadius: 12, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: p.surfaceAlt,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                style: TextStyle(fontSize: 14, color: p.textPrimary),
                decoration: InputDecoration(
                  hintText: AppStrings.t('messageField'),
                  hintStyle: TextStyle(color: p.textSecondary, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: AppColors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
  }
}
