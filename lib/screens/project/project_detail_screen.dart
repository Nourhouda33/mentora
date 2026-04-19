import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/collaboration_provider.dart';
import 'tabs/chat_tab.dart';
import 'tabs/tasks_tab.dart';
import 'tabs/files_tab.dart';
import 'tabs/meetings_tab.dart';
import 'tabs/info_tab.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, String> _memberNames = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _loadMembers());
  }

  Future<void> _loadMembers() async {
    final project =
        ModalRoute.of(context)!.settings.arguments as ProjectModel;
    final Map<String, String> result = {};
    for (final uid in project.members) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        final d = doc.data() as Map<String, dynamic>;
        result[uid] = d['name'] ?? d['email'] ?? uid;
      } else {
        result[uid] = uid;
      }
    }
    if (mounted) setState(() => _memberNames = result);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettingsProvider>();
    final project =
        ModalRoute.of(context)!.settings.arguments as ProjectModel;

    return Scaffold(
      backgroundColor: context.mt.background,
      appBar: AppBar(
        backgroundColor: context.mt.background,
        elevation: 0,
        iconTheme: IconThemeData(color: context.mt.textPrimary),
        title: Text(
          project.name,
          style: GoogleFonts.sora(
            color: context.mt.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(Icons.videocam_outlined, color: context.mt.textPrimary, size: 20),
            ),
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.meetingRoom,
              arguments: project,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(84),
          child: Column(
            children: [
              // ── Dynamic members row ─────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    if (_memberNames.isEmpty)
                      Text(
                        '${project.members.length} member${project.members.length == 1 ? '' : 's'}',
                        style: GoogleFonts.sora(
                            color: context.mt.textSecondary, fontSize: 12),
                      )
                    else ...[
                      _MemberAvatarRow(memberNames: _memberNames),
                      const SizedBox(width: 8),
                      Text(
                        '${_memberNames.length} member${_memberNames.length == 1 ? '' : 's'}',
                        style: GoogleFonts.sora(
                            color: context.mt.textSecondary, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              // ── Tabs ────────────────────────────────────────────
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppColors.primary,
                indicatorWeight: 2,
                labelColor: context.mt.textPrimary,
                unselectedLabelColor: context.mt.textSecondary,
                labelStyle: GoogleFonts.sora(
                    fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.sora(
                    fontSize: 13, fontWeight: FontWeight.w400),
                tabs: [
                  Tab(text: s.t('chat')),
                  Tab(text: s.t('tasks')),
                  Tab(text: s.t('meetings')),
                  Tab(text: s.t('files')),
                  const Tab(text: 'Info'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ChatTab(project: project),
          TasksTab(project: project),
          MeetingsTab(project: project),
          FilesTab(project: project),
          InfoTab(project: project),
        ],
      ),
    );
  }
}

// ── Dynamic member avatar row ─────────────────────────────────────────────────
class _MemberAvatarRow extends StatelessWidget {
  final Map<String, String> memberNames;
  const _MemberAvatarRow({required this.memberNames});

  Color _color(String name) {
    const colors = [
      AppColors.primary,
      Color(0xFFFF7B7B),
      AppColors.success,
      AppColors.inProgressOrange,
      AppColors.accent,
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final names = memberNames.values.toList();
    final show = names.length > 4 ? 4 : names.length;
    final extra = names.length - 4;

    return SizedBox(
      width: show * 18.0 + (extra > 0 ? 24 : 4),
      height: 26,
      child: Stack(
        children: [
          ...List.generate(show, (i) => Positioned(
                left: i * 18.0,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _color(names[i]),
                    border: Border.all(
                        color: context.mt.background, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      names[i][0].toUpperCase(),
                      style: GoogleFonts.sora(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              )),
          if (extra > 0)
            Positioned(
              left: show * 18.0,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border:
                      Border.all(color: context.mt.background, width: 1.5),
                ),
                child: Center(
                  child: Text('+$extra',
                      style: GoogleFonts.sora(
                          color: context.mt.textSecondary,
                          fontSize: 8,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
