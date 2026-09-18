import 'dart:async';

import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/chat.dart';
import '../services/chat_api.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';
import 'services_screen.dart' show categoryLabel;

/// Chat list (mockup page 20): search and a list of real per-booking
/// conversations, polled every 15s so a new reply shows up without a manual
/// refresh (same pattern as BookingsStore/NotificationsStore).
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  List<ChatThread> _threads = const [];
  bool _loading = true;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 15), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final threads = await ChatApi.instance.myThreads();
      if (!mounted) return;
      setState(() {
        _threads = threads;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<ChatThread> get _visible {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _threads;
    return _threads
        .where((t) => t.otherPartyName.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final items = _visible;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: _buildSearchField(),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _loading
                  ? const Center(
                      child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2)))
                  : items.isEmpty
                      ? Center(
                          child: Text(AppStrings.t('noConversations'),
                              style: TextStyle(color: p.textSecondary)),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: EdgeInsets.fromLTRB(
                                20, 8, 20, 110 + bottomInset),
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 4),
                            itemBuilder: (context, i) => _threadTile(items[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => MainShell.of(context)?.goToTab(0),
            icon: Icon(Icons.arrow_back, color: p.textPrimary),
          ),
          Expanded(
            child: Center(
              child: Text(AppStrings.t('navChat'),
                  style:
                      AppText.h2.copyWith(fontSize: 20, color: p.textPrimary)),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    final p = context.pal;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: p.shadow, blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(fontSize: 15, color: p.textPrimary),
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: AppStrings.t('search'),
          hintStyle: TextStyle(color: p.textSecondary, fontSize: 15),
          prefixIcon: Icon(Icons.search, color: p.textSecondary, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Widget _threadTile(ChatThread t) {
    final p = context.pal;
    final hasMessage = t.lastMessage != null && t.lastMessage!.isNotEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () =>
          Navigator.of(context).pushNamed('/chat-thread', arguments: t),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: p.surfaceAlt,
              child: const Icon(Icons.person,
                  color: AppColors.primaryBlue, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.otherPartyName,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    hasMessage
                        ? '${t.lastMessageMine ? "${AppStrings.t('you')}: " : ""}${t.lastMessage}'
                        : categoryLabel(t.category),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: p.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (t.lastMessageAt != null)
              Text(_timeLabel(t.lastMessageAt!),
                  style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
          ],
        ),
      ),
    );
  }

  static String _timeLabel(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }
}
