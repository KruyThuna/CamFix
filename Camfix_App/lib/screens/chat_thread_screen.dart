import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../models/chat.dart';
import '../services/api_client.dart';
import '../services/chat_api.dart';
import '../theme/app_theme.dart';
import 'services_screen.dart' show categoryLabel;

/// A real chat with the technician on one booking (`/api/chats/{jobId}`).
/// Polls for new messages every few seconds while open; opening it marks
/// the technician's messages as read on the server.
///
/// Route argument: [ChatThreadArgs].
class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({super.key});

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  ChatThreadArgs? _args;
  final List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  Timer? _poll;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_args != null) return;
    _args = ModalRoute.of(context)?.settings.arguments as ChatThreadArgs?;
    if (_args == null) return;
    _load();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      // Full reload keeps read receipts ("Seen") up to date; threads are
      // small (one booking), so this stays cheap.
      final list = await ChatApi.instance.messages(_args!.jobId);
      if (!mounted) return;
      final grew = list.length > _messages.length;
      setState(() {
        _messages
          ..clear()
          ..addAll(list);
        _loading = false;
        _error = null;
      });
      if (grew) _scrollToEnd();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final m = await ChatApi.instance.send(_args!.jobId, text);
      if (!mounted) return;
      _controller.clear();
      setState(() => _messages.add(m));
      _scrollToEnd();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${AppStrings.t('messageNotSent')}: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToEnd() {
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

  static String _time(DateTime? d) {
    if (d == null) return '';
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    if (day == today) return AppStrings.t('today');
    if (day == today.subtract(const Duration(days: 1))) {
      return AppStrings.t('yesterday');
    }
    return '${_months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final args = _args;
    if (args == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(AppStrings.t('noConversations'))),
      );
    }

    // Day dividers between messages from different days.
    final rows = <Widget>[];
    DateTime? lastDay;
    for (var i = 0; i < _messages.length; i++) {
      final m = _messages[i];
      final c = m.createdAt;
      if (c != null) {
        final day = DateTime(c.year, c.month, c.day);
        if (lastDay == null || day != lastDay) {
          rows.add(_dayDivider(_dayLabel(c)));
          lastDay = day;
        }
      }
      final isLastMine =
          m.mine && !_messages.skip(i + 1).any((later) => later.mine);
      rows.add(_messageRow(m, showSeen: isLastMine));
    }

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(args),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              _error ?? AppStrings.t('chatEmptyHint'),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: p.textSecondary),
                            ),
                          ),
                        )
                      : ListView(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          children: rows,
                        ),
            ),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ChatThreadArgs c) {
    final p = context.pal;
    final photo = c.technicianId == null
        ? null
        : '${ApiClient.instance.baseUrl}/api/technician/${c.technicianId}/photo';
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
            foregroundImage: photo == null ? null : NetworkImage(photo),
            onForegroundImageError: photo == null ? null : (_, __) {},
            child: const Icon(Icons.person,
                color: AppColors.primaryBlue, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary)),
                Text(
                  [
                    if ((c.category ?? '').isNotEmpty)
                      categoryLabel(c.category!),
                    '${AppStrings.t('bookingHash')}${c.jobId}',
                  ].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: p.textSecondary),
                ),
              ],
            ),
          ),
          if ((c.phone ?? '').isNotEmpty)
            IconButton(
              tooltip: AppStrings.t('call'),
              onPressed: () => launchUrl(Uri.parse('tel:${c.phone}')),
              icon: const Icon(Icons.call_outlined,
                  color: AppColors.primaryBlue, size: 20),
            ),
          IconButton(
            tooltip: AppStrings.t('trackBooking'),
            onPressed: () => Navigator.of(context)
                .pushNamed('/booking-tracking', arguments: c.jobId),
            icon: const Icon(Icons.receipt_long_outlined,
                color: AppColors.primaryBlue, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _dayDivider(String label) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
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
      ),
    );
  }

  Widget _messageRow(ChatMessage m, {required bool showSeen}) {
    final p = context.pal;
    final mine = m.mine;
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
              m.body,
              style: TextStyle(
                fontSize: 14,
                color: mine ? AppColors.white : p.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
              showSeen && m.readAt != null
                  ? '${_time(m.createdAt)} • ${AppStrings.t('seen')}'
                  : _time(m.createdAt),
              style: TextStyle(fontSize: 10.5, color: p.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    final p = context.pal;
    final canSend = _controller.text.trim().isNotEmpty && !_sending;
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
                minLines: 1,
                maxLines: 4,
                maxLength: 2000,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                onChanged: (_) => setState(() {}),
                style: TextStyle(fontSize: 14, color: p.textPrimary),
                decoration: InputDecoration(
                  hintText: AppStrings.t('messageField'),
                  hintStyle: TextStyle(color: p.textSecondary, fontSize: 14),
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: canSend ? _send : null,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: canSend
                    ? AppColors.primaryBlue
                    : AppColors.primaryBlue.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.white),
                    )
                  : const Icon(Icons.send_rounded,
                      color: AppColors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
