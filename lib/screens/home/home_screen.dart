import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/collaboration_provider.dart';
import '../../providers/notification_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Stream<List<ProjectModel>> _projectsStream;

  @override
  void initState() {
    super.initState();
    _projectsStream =
        context.read<CollaborationProvider>().projectsStream();
    context.read<NotificationProvider>().listenToNotifications();
  }

  String get _firstName {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? user?.email?.split('@').first ?? 'User';
    return name.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _BottomBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.sora(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        TextSpan(text: '${s.t('hello')}, $_firstName '),
                        const TextSpan(text: '👋'),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const _NotificationBell(),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.profile),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.5),
                          width: 2,
                        ),
                        color: AppColors.surface,
                      ),
                      child: const Icon(Icons.person,
                          color: AppColors.textSecondary, size: 26),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.t('my_projects'),
                      style: GoogleFonts.sora(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.joinProject),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: const Icon(Icons.qr_code_scanner_rounded,
                          color: AppColors.textPrimary, size: 22),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.newProject),
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                      ),
                      child: Center(
                        child: Text(
                          '+ ${s.t('new_project_btn')}',
                          style: GoogleFonts.sora(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // ── Real-time project list ──────────────────────────
              Expanded(
                child: StreamBuilder<List<ProjectModel>>(
                  stream: _projectsStream,
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting &&
                        !snap.hasData) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary));
                    }
                    final projects = snap.data ?? [];
                    if (projects.isEmpty) {
                      return Center(
                        child: Text(s.t('no_projects'),
                            style: GoogleFonts.sora(
                                color: AppColors.textSecondary,
                                fontSize: 14)),
                      );
                    }
                    return ListView.builder(
                      itemCount: projects.length,
                      itemBuilder: (ctx, i) => _ProjectCard(
                        project: projects[i],
                        accentColor: _cardAccent(i),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _cardAccent(int i) {
    const c = [AppColors.primary, AppColors.primary, AppColors.inProgressOrange];
    return c[i % c.length];
  }
}

// ── 🔔 Notification Bell ──────────────────────────────────────────────────────
class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    final notif = context.watch<NotificationProvider>();
    final unread = notif.unreadCount;

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      constraints: const BoxConstraints(minWidth: 300, maxWidth: 340),
      onSelected: (_) {},
      itemBuilder: (_) => [
        // ── Header row ─────────────────────────────────────────────
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: _NotifHeader(
            unread: unread,
            onMarkAll: () => context.read<NotificationProvider>().markAllRead(),
          ),
        ),
        // ── Divider ────────────────────────────────────────────────
        const PopupMenuDivider(height: 1),
        // ── Notification items ─────────────────────────────────────
        if (notif.notifications.isEmpty)
          PopupMenuItem(
            enabled: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No notifications yet',
                  style: GoogleFonts.sora(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          )
        else
          ...notif.notifications.take(8).map(
                (n) => PopupMenuItem(
                  padding: EdgeInsets.zero,
                  onTap: () =>
                      context.read<NotificationProvider>().markRead(n.id),
                  child: _NotifItem(notification: n),
                ),
              ),
      ],
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(
              unread > 0
                  ? Icons.notifications_rounded
                  : Icons.notifications_outlined,
              color: unread > 0 ? AppColors.primary : AppColors.textSecondary,
              size: 22,
            ),
          ),
          // Badge
          if (unread > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: GoogleFonts.sora(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Notification dropdown header ──────────────────────────────────────────────
class _NotifHeader extends StatelessWidget {
  final int unread;
  final VoidCallback onMarkAll;

  const _NotifHeader({required this.unread, required this.onMarkAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
      child: Row(
        children: [
          Text(
            'Notifications',
            style: GoogleFonts.sora(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (unread > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$unread',
                style: GoogleFonts.sora(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (unread > 0)
            GestureDetector(
              onTap: onMarkAll,
              child: Text(
                'Mark all read',
                style: GoogleFonts.sora(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Single notification item ──────────────────────────────────────────────────
class _NotifItem extends StatelessWidget {
  final AppNotification notification;
  const _NotifItem({required this.notification});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return Container(
      color: isUnread
          ? AppColors.primary.withOpacity(0.06)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unread dot
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnread ? AppColors.primary : Colors.transparent,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: GoogleFonts.sora(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight:
                        isUnread ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  notification.message,
                  style: GoogleFonts.sora(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _timeAgo(notification.date),
                  style: GoogleFonts.sora(
                    color: AppColors.textSecondary.withOpacity(0.6),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Project Card ──────────────────────────────────────────────────────────────
class _ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final Color accentColor;
  const _ProjectCard({required this.project, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final members = project.members;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.projectDetail,
        arguments: project,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border(left: BorderSide(color: accentColor, width: 3)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  project.name,
                  style: GoogleFonts.sora(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (members.isNotEmpty) _MemberAvatars(members: members),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Member avatars ────────────────────────────────────────────────────────────
class _MemberAvatars extends StatelessWidget {
  final List<String> members;
  const _MemberAvatars({required this.members});

  @override
  Widget build(BuildContext context) {
    const maxShow = 3;
    final show = members.length > maxShow ? maxShow : members.length;
    final extra = members.length - maxShow;
    return SizedBox(
      width: show * 22.0 + (extra > 0 ? 28 : 0),
      height: 28,
      child: Stack(
        children: [
          for (int i = 0; i < show; i++)
            Positioned(left: i * 20.0, child: _Avatar(seed: members[i])),
          if (extra > 0)
            Positioned(
              left: show * 20.0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 1.5),
                ),
                child: Center(
                  child: Text('+$extra',
                      style: GoogleFonts.sora(
                          color: AppColors.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String seed;
  const _Avatar({required this.seed});

  Color _color(String s) {
    const c = [
      Color(0xFF6C9EFF), Color(0xFFFF7B7B),
      Color(0xFF3DDC84), Color(0xFFFFB020), Color(0xFF7B6FFF),
    ];
    return c[s.hashCode.abs() % c.length];
  }

  @override
  Widget build(BuildContext context) => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _color(seed),
          border: Border.all(color: AppColors.surface, width: 1.5),
        ),
        child: Center(
          child: Text(
            seed.isNotEmpty ? seed[0].toUpperCase() : '?',
            style: GoogleFonts.sora(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
      );
}

// ── Bottom bar ────────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Color(0xFF252D40), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.home_rounded, color: AppColors.primary, size: 22),
              const SizedBox(height: 3),
              Text('Home',
                  style: GoogleFonts.sora(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
