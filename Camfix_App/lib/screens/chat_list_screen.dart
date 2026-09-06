import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/chat.dart';
import '../theme/app_theme.dart';

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

  static const List<ChatContact> _contacts = [
    ChatContact(
        name: 'Vanna Sok',
        lastMessage: "Hey, What's up",
        time: '12:17 PM',
        online: true),
    ChatContact(name: 'Reak Smey', lastMessage: 'Hello', time: '12:00 PM'),
    ChatContact(
        name: 'Vanna Doung',
        lastMessage: 'Hello',
        time: '12:00 PM',
        unreadCount: 1),
    ChatContact(
        name: 'Mean Dara',
        lastMessage: 'Hey',
        time: '12:00 PM',
        unreadCount: 1),
  ];

  int get _unreadTotal => _contacts.where((c) => c.unreadCount > 0).length;

  List<ChatContact> get _visible {
    final q = _query.trim().toLowerCase();
    return _contacts.where((c) {
      if (_unreadOnly && c.unreadCount == 0) return false;
      if (q.isNotEmpty && !c.name.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  @override
  void dispose() {
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
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: _buildSearchField(),
            ),
            const SizedBox(height: 14),
            _buildFilters(),
            const SizedBox(height: 6),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(AppStrings.t('noConversations'),
                          style: TextStyle(color: p.textSecondary)),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                          20, 8, 20, 110 + bottomInset),
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

  Widget _buildHeader() {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: p.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: p.shadow,
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Icon(Icons.arrow_back, color: p.textPrimary, size: 20),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(AppStrings.t('navChat'),
                  style: AppText.h2
                      .copyWith(fontSize: 20, color: p.textPrimary)),
            ),
          ),
          const SizedBox(width: 44),
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

  Widget _contactTile(ChatContact c) {
    final p = context.pal;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () =>
          Navigator.of(context).pushNamed('/chat-thread', arguments: c),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: p.surfaceAlt,
                  child: const Icon(Icons.person,
                      color: AppColors.primaryBlue, size: 26),
                ),
                if (c.online)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71),
                        shape: BoxShape.circle,
                        border: Border.all(color: p.background, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    c.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: p.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(c.time,
                    style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
                const SizedBox(height: 6),
                if (c.unreadCount > 0)
                  Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${c.unreadCount}',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
