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

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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

    // Demo members list
    final demoMembers = ['Ahmed', 'Lina', 'Sara', 'David'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          project.name,
          style: GoogleFonts.sora(
            color: AppColors.textPrimary,
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
              child: const Icon(
                Icons.videocam_outlined,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.meetingRoom,
              arguments: project,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Column(
            children: [
              // ── Members sub-header ──────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    _MemberAvatarRow(members: demoMembers),
                    const SizedBox(width: 8),
                    Text(
                      '+${demoMembers.length} members',
                      style: GoogleFonts.sora(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // ── Tabs ────────────────────────────────────────────
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                indicatorWeight: 2,
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: GoogleFonts.sora(
                    fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.sora(
                    fontSize: 13, fontWeight: FontWeight.w400),
                tabs: [
                  Tab(text: s.t('chat')),
                  Tab(text: s.t('tasks')),
                  Tab(text: s.t('meetings')),
                  Tab(text: s.t('files')),
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
        ],
      ),
    );
  }
}

// ── Small stacked avatars ─────────────────────────────────────────────────────
class _MemberAvatarRow extends StatelessWidget {
  final List<String> members;
  const _MemberAvatarRow({required this.members});

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
    final show = members.length > 3 ? 3 : members.length;
    return SizedBox(
      width: show * 18.0 + 4,
      height: 26,
      child: Stack(
        children: List.generate(show, (i) {
          return Positioned(
            left: i * 18.0,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _color(members[i]),
                border: Border.all(color: AppColors.background, width: 1.5),
              ),
              child: Center(
                child: Text(
                  members[i][0].toUpperCase(),
                  style: GoogleFonts.sora(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
