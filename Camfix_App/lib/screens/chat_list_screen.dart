import 'dart:async';

import 'package:flutter/material.dart';
import '../app_settings.dart';
import '../l10n/app_strings.dart';
import '../models/chat.dart';
import '../services/api_client.dart';
import '../services/chat_api.dart';
import '../services/notifications_store.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';
import 'services_screen.dart' show categoryLabel;

/// Chat list (mockup page 20): search, All / Unread filter and a list of
/// conversations. Tapping one opens the thread at `/chat-thread`.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _unreadOnly = false;

  /// Real conversations - one per booking that has a technician
  /// (`GET /api/chats`), refreshed every few seconds while visible.
  List<ChatThread> _threads = const [];
  bool _loading = true;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 8), (_) => _load());
  }

  Future<void> _load() async {
    try {
      final list = await ChatApi.instance.threads();
      if (mounted) {
        setState(() {
          _threads = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _unreadTotal => _threads.where((c) => c.unreadCount > 0).length;

  List<ChatThread> get _visible {
    final q = _query.trim().toLowerCase();
    return _threads.where((c) {
      if (_unreadOnly && c.unreadCount == 0) return false;
      if (q.isNotEmpty &&
          !c.otherName.toLowerCase().contains(q) &&
          !categoryLabel(c.category).toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _open(ChatThread t) async {
    await Navigator.of(context)
        .pushNamed('/chat-thread', arguments: ChatThreadArgs.fromThread(t));
    _load(); // unread counts changed
  }

  static String _timeLabel(DateTime? d) {
    if (d == null) return '';
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
      return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'AM' : 'PM'}';
    }
    return '${d.day}/${d.month}/${d.year % 100}';
  }

  @override
  void dispose() {
    _poll?.cancel();
    _searchController.dispose();
    super.dispose();
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _buildSearchField(),
            ),
            const SizedBox(height: 14),
            _buildFilters(),
            const SizedBox(height: 6),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                                AppStrings.t(_threads.isEmpty
                                    ? 'noConversationsYet'
                                    : 'noConversations'),
                                textAlign: TextAlign.center,
                                style: TextStyle(color: p.textSecondary)),
                          ),
                        )
                      : ListView.separated(
                          padding:
                              EdgeInsets.fromLTRB(20, 8, 20, 110 + bottomInset),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 4),
                          itemBuilder: (context, i) => _contactTile(items[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  /// Same app top bar as the Dashboard tab (logo, favorites, notifications,
  /// profile) plus the location row - this is a top-level tab, not a pushed
  /// subpage, so it keeps the shell's chrome instead of a back-arrow title.
  Widget _buildHeader() {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            IconButton.filled(
              tooltip: 'Menu',
              style:
                  IconButton.styleFrom(backgroundColor: AppColors.primaryBlue),
              onPressed: () => MainShell.of(context)?.goToTab(0),
              icon: const Icon(Icons.home_repair_service_rounded,
                  color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('CAMFIX',
                  style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 18,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w900)),
            ),
            IconButton(
              tooltip: 'Favorites',
              onPressed: () => Navigator.of(context).pushNamed('/favorites'),
              icon: const Icon(Icons.favorite_border_rounded,
                  color: Colors.redAccent),
            ),
            _bellIcon(),
          ]),
          InkWell(
            onTap: () => MainShell.of(context)?.goToTab(3),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(children: [
                const Icon(Icons.location_on_outlined, size: 16),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    AppSettings.instance.defaultAddress ??
                        AppStrings.t('pickLocation'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: p.textPrimary),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconCircle(IconData icon, {required VoidCallback onTap}) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.white,
        child: Icon(icon, color: AppColors.textDark, size: 20),
      ),
    );
  }

  Widget _bellIcon() {
    final unread = NotificationsStore.instance.unread;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _iconCircle(
          Icons.notifications_none_rounded,
          onTap: () async {
            await Navigator.of(context).pushNamed('/notifications');
            NotificationsStore.instance.refresh();
          },
        ),
        if (unread > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFE23D3D),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.white, width: 1.5),
              ),
              child: Text(
                unread > 9 ? '9+' : '$unread',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchField() {
    final p = context.pal;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: p.shadow, blurRadius: 12, offset: const Offset(0, 4)),
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

  Widget _buildFilters() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _filterChip(AppStrings.t('all'),
                selected: !_unreadOnly,
                onTap: () => setState(() => _unreadOnly = false)),
            const SizedBox(width: 10),
            _filterChip('${AppStrings.t('unread')} $_unreadTotal',
                selected: _unreadOnly,
                onTap: () => setState(() => _unreadOnly = true)),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label,
      {required bool selected, required VoidCallback onTap}) {
    final p = context.pal;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlue : p.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryBlue : p.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.white : p.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _contactTile(ChatThread c) {
    final p = context.pal;
    final photo = c.otherTechnicianId == null
        ? null
        : '${ApiClient.instance.baseUrl}/api/technician/${c.otherTechnicianId}/photo';
    final unread = c.unreadCount > 0;
    final preview = c.lastMessage == null
        ? AppStrings.t('chatStartPrompt')
        : '${c.lastMine ? '${AppStrings.t('youPrefix')} ' : ''}${c.lastMessage}';
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _open(c),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: p.surfaceAlt,
              foregroundImage: photo == null ? null : NetworkImage(photo),
              onForegroundImageError: photo == null ? null : (_, __) {},
              child: const Icon(Icons.person,
                  color: AppColors.primaryBlue, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.otherName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary)),
                  Text(
                    '${categoryLabel(c.category)} • ${AppStrings.t('bookingHash')}${c.jobId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.primaryBlue),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
                        color: unread ? p.textPrimary : p.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_timeLabel(c.lastAt),
                    style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
                const SizedBox(height: 6),
                if (unread)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 18),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      c.unreadCount > 9 ? '9+' : '${c.unreadCount}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700),
                    ),
                  )
                else
                  const SizedBox(height: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
