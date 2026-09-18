import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../lang_aware.dart';
import '../models/chat.dart';
import '../services/chat_api.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Chat with the customer on one job. Polls every 5s while open so a reply
/// shows up without leaving the screen - same per-booking thread the
/// customer app's ChatThreadScreen shows, via the same backend endpoints.
class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({super.key});

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen>
    with LangAware<ChatThreadScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  int? _jobId;
  String _customerName = '';
  List<ChatMessage> _messages = const [];
  bool _loading = true;
  bool _sending = false;
  Timer? _poll;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_jobId != null) return;
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    _jobId = args['jobId'] as int;
    _customerName = (args['name'] as String?) ?? '';
    _load();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    final jobId = _jobId;
    if (jobId == null) return;
    if (!silent) setState(() => _loading = true);
    try {
      final messages = await ChatApi.instance.messages(jobId);
      if (!mounted) return;
      final grew = messages.length > _messages.length;
      setState(() {
        _messages = messages;
        _loading = false;
      });
      if (grew) _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (!silent) showError(context, e);
    }
  }

  Future<void> _send() async {
    final jobId = _jobId;
    final text = _controller.text.trim();
    if (jobId == null || text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _controller.clear();
    try {
      final sent = await ChatApi.instance.send(jobId, text);
      if (!mounted) return;
      setState(() => _messages = [..._messages, sent]);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      _controller.text = text;
      showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
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
    return Scaffold(
      appBar: AppBar(title: Text(_customerName)),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(AppStrings.t('sayHello'),
                            style: TextStyle(color: p.textSecondary)),
                      )
                    : ListView(
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
        child: Text(label,
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: p.textSecondary)),
      ),
    );
  }

  Widget _messageRow(ChatMessage m) {
    final p = context.pal;
    final bool mine = m.mine;
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
          Text(_timeLabel(m.createdAt),
              style: TextStyle(fontSize: 10.5, color: p.textSecondary)),
        ],
      ),
    );
  }

  static String _timeLabel(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  Widget _buildComposer() {
    final p = context.pal;
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, 12 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: p.surface,
        boxShadow: [
          BoxShadow(
              color: p.shadow, blurRadius: 12, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
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
              onTap: _sending ? null : _send,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue
                      .withValues(alpha: _sending ? 0.5 : 1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded,
                    color: AppColors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
