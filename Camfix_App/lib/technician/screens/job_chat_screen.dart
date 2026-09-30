import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../models/chat_message.dart';
import '../models/tech_job.dart';
import '../services/chat_api.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Real chat with the customer on one job. Polls every few seconds while
/// open; opening it marks the customer's messages as read.
///
/// Route argument: the [TechJob].
class JobChatScreen extends StatefulWidget {
  const JobChatScreen({super.key});

  @override
  State<JobChatScreen> createState() => _JobChatScreenState();
}

class _JobChatScreenState extends State<JobChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  TechJob? _job;
  List<ChatMessage> _messages = const [];
  bool _loading = true;
  bool _sending = false;
  Timer? _poll;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_job != null) return;
    _job = ModalRoute.of(context)!.settings.arguments as TechJob;
    _load();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await ChatApi.instance.messages(_job!.id);
      if (!mounted) return;
      final grew = list.length > _messages.length;
      setState(() {
        _messages = list;
        _loading = false;
      });
      if (grew) _toEnd();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final m = await ChatApi.instance.send(_job!.id, text);
      if (!mounted) return;
      _controller.clear();
      setState(() => _messages = [..._messages, m]);
      _toEnd();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _toEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  static String _time(DateTime? d) {
    if (d == null) return '';
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '${d.day}/${d.month}  $h:${d.minute.toString().padLeft(2, '0')} '
        '${d.hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final j = _job!;
    final lastMineIndex = _messages.lastIndexWhere((m) => m.mine);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              j.customerName.isEmpty
                  ? AppStrings.t('customer')
                  : j.customerName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              '${AppStrings.t('jobHash')}${j.id} • ${AppStrings.category(j.category)}',
              style: TextStyle(fontSize: 12, color: p.textSecondary),
            ),
          ],
        ),
        actions: [
          if (j.customerPhone.isNotEmpty)
            IconButton(
              onPressed: () => launchUrl(Uri.parse('tel:${j.customerPhone}')),
              icon: const Icon(Icons.call_outlined),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            AppStrings.t('chatEmptyTech'),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: p.textSecondary),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final m = _messages[i];
                          final seen = i == lastMineIndex && m.readAt != null;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Column(
                              crossAxisAlignment: m.mine
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                            0.74,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: m.mine
                                        ? AppColors.primaryBlue
                                        : p.surfaceAlt,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft:
                                          Radius.circular(m.mine ? 16 : 4),
                                      bottomRight:
                                          Radius.circular(m.mine ? 4 : 16),
                                    ),
                                  ),
                                  child: Text(
                                    m.body,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          m.mine ? Colors.white : p.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  seen
                                      ? '${_time(m.createdAt)} • ${AppStrings.t('seen')}'
                                      : _time(m.createdAt),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: p.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: AppStrings.t('typeMessage'),
                        counterText: '',
                        isDense: true,
                        filled: true,
                        fillColor: p.surfaceAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _controller.text.trim().isEmpty || _sending
                        ? null
                        : _send,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      minimumSize: const Size(46, 46),
                    ),
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
