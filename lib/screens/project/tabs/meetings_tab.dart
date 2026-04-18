import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../core/routes.dart';
import '../../../providers/app_settings_provider.dart';
import '../../../providers/collaboration_provider.dart';

const _demoMembers = ['Ahmed', 'Lina', 'Sara', 'David'];

class MeetingsTab extends StatefulWidget {
  final ProjectModel project;
  const MeetingsTab({super.key, required this.project});

  @override
  State<MeetingsTab> createState() => _MeetingsTabState();
}

class _MeetingsTabState extends State<MeetingsTab> {
  // Demo upcoming (mutable so we can add)
  final List<_UpcomingEntry> _upcoming = [
    _UpcomingEntry(
      label: 'Monday, April 14',
      time: '10:00 AM',
      badge: 'In 3 days',
      badgeColor: AppColors.primary,
    ),
    _UpcomingEntry(
      label: 'Tuesday, April 15',
      time: '2:30 PM',
      badge: 'Tomorrow',
      badgeColor: AppColors.inProgressOrange,
    ),
  ];

  static final _past = [
    _PastEntry(label: 'Apr 5', duration: '38 min', participants: 3),
    _PastEntry(label: 'Apr 2', duration: '1h 15min', participants: 5),
    _PastEntry(label: 'Mar 28', duration: '45 min', participants: 1),
  ];

  // ── Schedule dialog ──────────────────────────────────────────────────────
  Future<void> _showScheduleDialog() async {
    final titleCtrl = TextEditingController();
    DateTime? pickedDate;
    TimeOfDay? pickedTime;
    final selectedMembers = <String>{};

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md)),
          title: Text(
            'Schedule Meeting',
            style: GoogleFonts.sora(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                _DlgLabel('Title'),
                const SizedBox(height: 6),
                _DlgField(controller: titleCtrl, hint: 'Meeting title...'),
                const SizedBox(height: 14),

                // Date picker
                _DlgLabel('Date'),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                      builder: (c, child) => Theme(
                        data: Theme.of(c).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppColors.primary,
                            surface: AppColors.surface,
                            onSurface: AppColors.textPrimary,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (d != null) setDlg(() => pickedDate = d);
                  },
                  child: _DlgPickerBox(
                    label: pickedDate == null
                        ? 'Pick a date'
                        : '${pickedDate!.day}/${pickedDate!.month}/${pickedDate!.year}',
                    icon: Icons.calendar_today_outlined,
                  ),
                ),
                const SizedBox(height: 14),

                // Time picker
                _DlgLabel('Time'),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final t = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.now(),
                      builder: (c, child) => Theme(
                        data: Theme.of(c).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppColors.primary,
                            surface: AppColors.surface,
                            onSurface: AppColors.textPrimary,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (t != null) setDlg(() => pickedTime = t);
                  },
                  child: _DlgPickerBox(
                    label: pickedTime == null
                        ? 'Pick a time'
                        : pickedTime!.format(ctx),
                    icon: Icons.access_time_rounded,
                  ),
                ),
                const SizedBox(height: 14),

                // Members multi-select
                _DlgLabel('Invite Members'),
                const SizedBox(height: 8),
                ..._demoMembers.map((m) => CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.primary,
                      checkColor: Colors.white,
                      title: Text(
                        m,
                        style: GoogleFonts.sora(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                      value: selectedMembers.contains(m),
                      onChanged: (v) => setDlg(() {
                        if (v == true) {
                          selectedMembers.add(m);
                        } else {
                          selectedMembers.remove(m);
                        }
                      }),
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.sora(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty || pickedDate == null) return;
                final timeStr = pickedTime?.format(ctx) ?? '12:00 PM';
                final dateStr = _formatDate(pickedDate!);
                final badge = _badgeLabel(pickedDate!);
                final badgeColor = _badgeColor(pickedDate!);

                setState(() {
                  _upcoming.add(_UpcomingEntry(
                    label: dateStr,
                    time: timeStr,
                    badge: badge,
                    badgeColor: badgeColor,
                  ));
                });

                // Also save to provider
                context.read<CollaborationProvider>().addMeeting(MeetingModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      projectId: widget.project.id,
                      title: titleCtrl.text.trim(),
                      date: pickedDate!,
                      link: '',
                      participants: selectedMembers.toList(),
                    ));

                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.sm)),
              ),
              child: Text('Confirm',
                  style: GoogleFonts.sora(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  static String _badgeLabel(DateTime d) {
    final now = DateTime.now();
    final diff = d.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return 'In $diff days';
  }

  static Color _badgeColor(DateTime d) {
    final now = DateTime.now();
    final diff = d.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff <= 1) return AppColors.inProgressOrange;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            // ── UPCOMING ────────────────────────────────────────────
            _SectionLabel('UPCOMING'),
            const SizedBox(height: 12),
            ..._upcoming.map((m) => _UpcomingCard(
                  entry: m,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.meetingRoom,
                    arguments: widget.project,
                  ),
                )),
            const SizedBox(height: 24),

            // ── PAST ────────────────────────────────────────────────
            _SectionLabel('PAST'),
            const SizedBox(height: 12),
            ..._past.map((p) => _PastRow(entry: p)),
          ],
        ),

        // ── + Schedule Meeting FAB ───────────────────────────────────
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: _showScheduleDialog,
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              'Schedule Meeting',
              style: GoogleFonts.sora(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Upcoming card ─────────────────────────────────────────────────────────────
class _UpcomingCard extends StatelessWidget {
  final _UpcomingEntry entry;
  final VoidCallback onTap;
  const _UpcomingCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.label,
                    style: GoogleFonts.sora(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.time,
                    style: GoogleFonts.sora(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: entry.badgeColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                entry.badge,
                style: GoogleFonts.sora(
                  color: entry.badgeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Past row ──────────────────────────────────────────────────────────────────
class _PastRow extends StatelessWidget {
  final _PastEntry entry;
  const _PastRow({required this.entry});

  Color _avatarColor(int i) {
    const colors = [
      AppColors.primary,
      Color(0xFFFF7B7B),
      AppColors.success,
      AppColors.inProgressOrange,
      AppColors.accent,
    ];
    return colors[i % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.label,
                    style: GoogleFonts.sora(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(entry.duration,
                    style: GoogleFonts.sora(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          SizedBox(
            width: entry.participants * 18.0 + 4,
            height: 28,
            child: Stack(
              children: List.generate(entry.participants, (i) => Positioned(
                    left: i * 18.0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _avatarColor(i),
                        border: Border.all(
                            color: AppColors.background, width: 1.5),
                      ),
                    ),
                  )),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.sora(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      );
}

// ── Dialog helpers ────────────────────────────────────────────────────────────
class _DlgLabel extends StatelessWidget {
  final String text;
  const _DlgLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.sora(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600),
      );
}

class _DlgField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _DlgField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        style: GoogleFonts.sora(color: AppColors.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.sora(color: AppColors.textSecondary, fontSize: 13),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      );
}

class _DlgPickerBox extends StatelessWidget {
  final String label;
  final IconData icon;
  const _DlgPickerBox({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 16),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.sora(
                    color: AppColors.textPrimary, fontSize: 13)),
          ],
        ),
      );
}

// ── Data models ───────────────────────────────────────────────────────────────
class _UpcomingEntry {
  final String label, time, badge;
  final Color badgeColor;
  _UpcomingEntry(
      {required this.label,
      required this.time,
      required this.badge,
      required this.badgeColor});
}

class _PastEntry {
  final String label, duration;
  final int participants;
  _PastEntry(
      {required this.label,
      required this.duration,
      required this.participants});
}
