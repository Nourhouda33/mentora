import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/collaboration_provider.dart';

// Demo members list — FIREBASE_DEMO_MODE
const _demoMembers = ['Ahmed', 'Lina', 'Sara', 'David', 'Alex Rivers'];

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _titleCtrl = TextEditingController();
  String _assignee = _demoMembers.first;
  TaskPriority _priority = TaskPriority.high;
  TaskStatus _status = TaskStatus.todo;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _create() {
    if (_titleCtrl.text.trim().isEmpty) return;

    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final project = args?['project'] as ProjectModel?;
    if (project == null) return;

    context.read<CollaborationProvider>().addTask(TaskModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          projectId: project.id,
          title: _titleCtrl.text.trim(),
          assignedTo: _assignee,
          priority: _priority,
          status: _status,
        ));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          'Create Task',
          style: GoogleFonts.sora(
            color: AppColors.primary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'AI OPTIMIZED',
                  style: GoogleFonts.sora(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Task Title ──────────────────────────────────────────
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Label('Task Title'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _titleCtrl,
                    style: GoogleFonts.sora(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g., Finalize Q4 Design System',
                      hintStyle: GoogleFonts.sora(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Assignee ────────────────────────────────────────────
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Label('Assignee'),
                      const Spacer(),
                      const Icon(Icons.people_outline,
                          color: AppColors.primary, size: 18),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _AssigneeDropdown(
                    value: _assignee,
                    members: _demoMembers,
                    onChanged: (v) => setState(() => _assignee = v!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Priority Level ──────────────────────────────────────
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Label('Priority Level'),
                  const SizedBox(height: 12),
                  _PriorityOption(
                    label: 'High',
                    icon: '!',
                    color: AppColors.error,
                    selected: _priority == TaskPriority.high,
                    onTap: () => setState(() => _priority = TaskPriority.high),
                  ),
                  const SizedBox(height: 8),
                  _PriorityOption(
                    label: 'Medium',
                    iconWidget: const Icon(Icons.menu_rounded,
                        color: AppColors.textSecondary, size: 18),
                    color: AppColors.inProgressOrange,
                    selected: _priority == TaskPriority.medium,
                    onTap: () =>
                        setState(() => _priority = TaskPriority.medium),
                  ),
                  const SizedBox(height: 8),
                  _PriorityOption(
                    label: 'Low',
                    iconWidget: const Icon(Icons.low_priority_rounded,
                        color: AppColors.textSecondary, size: 18),
                    color: AppColors.success,
                    selected: _priority == TaskPriority.low,
                    onTap: () => setState(() => _priority = TaskPriority.low),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Initial Status ──────────────────────────────────────
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Label('Initial Status'),
                  const SizedBox(height: 12),
                  _StatusToggle(
                    value: _status,
                    onChanged: (v) => setState(() => _status = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Create Task button ──────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _create,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Create Task',
                  style: GoogleFonts.sora(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Assignee dropdown ─────────────────────────────────────────────────────────
class _AssigneeDropdown extends StatelessWidget {
  final String value;
  final List<String> members;
  final ValueChanged<String?> onChanged;

  const _AssigneeDropdown({
    required this.value,
    required this.members,
    required this.onChanged,
  });

  Color _avatarColor(String name) {
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          onChanged: onChanged,
          selectedItemBuilder: (ctx) => members.map((m) {
            return Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _avatarColor(m),
                  ),
                  child: Center(
                    child: Text(
                      m[0].toUpperCase(),
                      style: GoogleFonts.sora(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  m,
                  style: GoogleFonts.sora(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          }).toList(),
          items: members.map((m) {
            return DropdownMenuItem<String>(
              value: m,
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _avatarColor(m),
                    ),
                    child: Center(
                      child: Text(
                        m[0].toUpperCase(),
                        style: GoogleFonts.sora(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    m,
                    style: GoogleFonts.sora(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Priority option row ───────────────────────────────────────────────────────
class _PriorityOption extends StatelessWidget {
  final String label;
  final String? icon;
  final Widget? iconWidget;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _PriorityOption({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.icon,
    this.iconWidget,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : AppColors.background,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: selected
              ? Border.all(color: color.withOpacity(0.5), width: 1.5)
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.sora(
                color: selected ? color : AppColors.textPrimary,
                fontSize: 14,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const Spacer(),
            if (icon != null)
              Text(
                icon!,
                style: TextStyle(
                  color: selected ? color : AppColors.textSecondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              )
            else if (iconWidget != null)
              iconWidget!,
          ],
        ),
      ),
    );
  }
}

// ── Status toggle ─────────────────────────────────────────────────────────────
class _StatusToggle extends StatelessWidget {
  final TaskStatus value;
  final ValueChanged<TaskStatus> onChanged;

  const _StatusToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        children: [
          _ToggleBtn(
            label: 'TO DO',
            selected: value == TaskStatus.todo,
            onTap: () => onChanged(TaskStatus.todo),
          ),
          _ToggleBtn(
            label: 'IN PROGRESS',
            selected: value == TaskStatus.inProgress,
            onTap: () => onChanged(TaskStatus.inProgress),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.sora(
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w400,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: child,
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.sora(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
