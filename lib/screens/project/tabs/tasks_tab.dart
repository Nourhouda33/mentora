import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../core/routes.dart';
import '../../../providers/collaboration_provider.dart';

class TasksTab extends StatefulWidget {
  final ProjectModel project;
  const TasksTab({super.key, required this.project});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  late final Stream<List<TaskModel>> _tasksStream;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tasksStream = context
        .read<CollaborationProvider>()
        .tasksStream(widget.project.id);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TaskModel>>(
      stream: _tasksStream,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        final tasks = snap.data ?? [];

        if (tasks.isEmpty) {
          return Stack(
            children: [
              Center(
                child: Text(
                  'No tasks yet. Add the first one!',
                  style: GoogleFonts.sora(
                      color: context.mt.textSecondary, fontSize: 14),
                ),
              ),
              _AddTaskFab(project: widget.project),
            ],
          );
        }

        final Map<String, List<TaskModel>> grouped = {};
        for (final t in tasks) {
          final key = t.assignedTo.isEmpty ? 'Unassigned' : t.assignedTo;
          grouped.putIfAbsent(key, () => []).add(t);
        }

        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              children: grouped.entries.map((entry) {
                return _MemberGroup(
                  memberName: entry.key,
                  tasks: entry.value,
                  project: widget.project,
                  currentUid: _uid,
                );
              }).toList(),
            ),
            _AddTaskFab(project: widget.project),
          ],
        );
      },
    );
  }
}

// ── FAB ───────────────────────────────────────────────────────────────────────
class _AddTaskFab extends StatelessWidget {
  final ProjectModel project;
  const _AddTaskFab({required this.project});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: FloatingActionButton.extended(
        heroTag: 'add_task',
        onPressed: () => Navigator.pushNamed(
          context,
          AppRoutes.createTask,
          arguments: {'project': project},
        ),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Task',
          style: GoogleFonts.sora(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ── Member group ──────────────────────────────────────────────────────────────
class _MemberGroup extends StatelessWidget {
  final String memberName;
  final List<TaskModel> tasks;
  final ProjectModel project;
  final String currentUid;

  const _MemberGroup({
    required this.memberName,
    required this.tasks,
    required this.project,
    required this.currentUid,
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
                  color: context.mt.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${tasks.length}',
                  style: GoogleFonts.sora(
                      color: context.mt.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        ...tasks.map((t) => _TaskRow(
              task: t,
              project: project,
              currentUid: currentUid,
            )),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ── Task row ──────────────────────────────────────────────────────────────────
class _TaskRow extends StatelessWidget {
  final TaskModel task;
  final ProjectModel project;
  final String currentUid;

  const _TaskRow({
    required this.task,
    required this.project,
    required this.currentUid,
  });

  bool get _canEdit =>
      task.assignedToUid == currentUid || project.ownerId == currentUid;

  @override
  Widget build(BuildContext context) {
    final collab = context.read<CollaborationProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: task.assignedToUid == currentUid
            ? Border.all(
                color: AppColors.primary.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: GoogleFonts.sora(
                    color: context.mt.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    decoration: task.status == TaskStatus.done
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (task.priority != TaskPriority.medium) ...[
                  const SizedBox(height: 4),
                  _PriorityChip(priority: task.priority),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (!_canEdit) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('You can only update your own tasks',
                      style: GoogleFonts.sora(color: Colors.white)),
                  backgroundColor: AppColors.error,
                  duration: const Duration(seconds: 2),
                ));
                return;
              }
              collab.cycleTaskStatus(task.id, project.id);
            },
            child: _StatusBadge(status: task.status),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (!_canEdit) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('You cannot delete this task',
                      style: GoogleFonts.sora(color: Colors.white)),
                  backgroundColor: AppColors.error,
                  duration: const Duration(seconds: 2),
                ));
                return;
              }
              collab.deleteTask(task.id, project.id);
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Priority chip ─────────────────────────────────────────────────────────────
class _PriorityChip extends StatelessWidget {
  final TaskPriority priority;
  const _PriorityChip({required this.priority});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (priority) {
      TaskPriority.high => ('HIGH', AppColors.error),
      TaskPriority.low => ('LOW', AppColors.success),
      TaskPriority.medium => ('MEDIUM', AppColors.inProgressOrange),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: GoogleFonts.sora(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5)),
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
      child: Text(label,
          style: GoogleFonts.sora(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5)),
    );
  }
}
