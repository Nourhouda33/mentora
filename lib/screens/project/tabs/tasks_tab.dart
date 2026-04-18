import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../core/routes.dart';
import '../../../providers/app_settings_provider.dart';
import '../../../providers/collaboration_provider.dart';

// FIREBASE_DEMO_MODE
const _currentUid = 'demo_user';
const _currentUser = 'Ahmed';

// Demo seed data shown when project has no tasks yet
final _demoTasks = [
  _DemoTask('Prepare presentation slides', 'Ahmed', TaskStatus.inProgress),
  _DemoTask('Finalize app prototype', 'Ahmed', TaskStatus.todo),
  _DemoTask('Send Figma link to team', 'Ahmed', TaskStatus.todo),
  _DemoTask('Write user stories', 'Lina', TaskStatus.done),
  _DemoTask('Create onboarding flow', 'Lina', TaskStatus.inProgress),
  _DemoTask('User research report', 'Sara', TaskStatus.inProgress),
];

class _DemoTask {
  final String title;
  final String assignedTo;
  final TaskStatus status;
  _DemoTask(this.title, this.assignedTo, this.status);
}

class TasksTab extends StatelessWidget {
  final ProjectModel project;
  const TasksTab({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final collab = context.watch<CollaborationProvider>();
    final realTasks = collab.tasksForProject(project.id);

    // Use demo tasks if no real tasks yet
    final Map<String, List<_TaskEntry>> grouped = {};

    if (realTasks.isEmpty) {
      for (final d in _demoTasks) {
        grouped.putIfAbsent(d.assignedTo, () => []).add(
              _TaskEntry(id: d.title, title: d.title, status: d.status),
            );
      }
    } else {
      for (final t in realTasks) {
        final key = t.assignedTo.isEmpty ? 'Unassigned' : t.assignedTo;
        grouped.putIfAbsent(key, () => []).add(
              _TaskEntry(id: t.id, title: t.title, status: t.status, real: t),
            );
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: grouped.entries.map((entry) {
        return _MemberGroup(
          memberName: entry.key,
          tasks: entry.value,
          project: project,
          isDemo: realTasks.isEmpty,
        );
      }).toList(),
    );
  }
}

class _TaskEntry {
  final String id;
  final String title;
  final TaskStatus status;
  final TaskModel? real;
  _TaskEntry(
      {required this.id,
      required this.title,
      required this.status,
      this.real});
}

// ── Member group ──────────────────────────────────────────────────────────────
class _MemberGroup extends StatelessWidget {
  final String memberName;
  final List<_TaskEntry> tasks;
  final ProjectModel project;
  final bool isDemo;

  const _MemberGroup({
    required this.memberName,
    required this.tasks,
    required this.project,
    required this.isDemo,
  });

  Color _avatarColor(String name) {
    const colors = [
      AppColors.primary,
      Color(0xFF3DDC84),
      Color(0xFFFF7B7B),
      AppColors.inProgressOrange,
      AppColors.accent,
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Member header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _avatarColor(memberName),
                ),
                child: Center(
                  child: Text(
                    memberName.isNotEmpty ? memberName[0].toUpperCase() : '?',
                    style: GoogleFonts.sora(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                memberName,
                style: GoogleFonts.sora(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Task items
        ...tasks.map((t) => _TaskRow(
              entry: t,
              project: project,
              isDemo: isDemo,
            )),

        // + Add task
        GestureDetector(
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.createTask,
            arguments: {'project': project, 'assignTo': memberName},
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, color: AppColors.textSecondary, size: 16),
                const SizedBox(width: 6),
                Text(
                  '+ Add task',
                  style: GoogleFonts.sora(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ── Task row ──────────────────────────────────────────────────────────────────
class _TaskRow extends StatelessWidget {
  final _TaskEntry entry;
  final ProjectModel project;
  final bool isDemo;

  const _TaskRow({
    required this.entry,
    required this.project,
    required this.isDemo,
  });

  @override
  Widget build(BuildContext context) {
    final collab = context.read<CollaborationProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              entry.title,
              style: GoogleFonts.sora(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Status badge
          GestureDetector(
            onTap: () {
              if (isDemo) return;
              if (entry.real == null) return;
              final assignedTo = entry.real!.assignedTo;
              if (assignedTo != _currentUser && assignedTo != _currentUid) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'You can only update your own tasks',
                      style: GoogleFonts.sora(color: Colors.white),
                    ),
                    backgroundColor: AppColors.error,
                    duration: const Duration(seconds: 2),
                  ),
                );
                return;
              }
              collab.cycleTaskStatus(entry.id, project.id);
            },
            child: _StatusBadge(status: entry.status),
          ),
          const SizedBox(width: 8),

          // Delete
          GestureDetector(
            onTap: () {
              if (isDemo) return;
              if (entry.real == null) return;
              final canDelete = entry.real!.assignedTo == _currentUser ||
                  entry.real!.assignedTo == _currentUid ||
                  project.ownerId == _currentUid;
              if (!canDelete) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'You cannot delete this task',
                      style: GoogleFonts.sora(color: Colors.white),
                    ),
                    backgroundColor: AppColors.error,
                    duration: const Duration(seconds: 2),
                  ),
                );
                return;
              }
              collab.deleteTask(entry.id, project.id);
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final TaskStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      TaskStatus.todo => ('TO DO', AppColors.textSecondary),
      TaskStatus.inProgress => ('IN PROGRESS', AppColors.inProgressOrange),
      TaskStatus.done => ('DONE', AppColors.success),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.sora(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
