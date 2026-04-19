import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../core/routes.dart';
import '../../../providers/collaboration_provider.dart';

class MeetingsTab extends StatefulWidget {
  final ProjectModel project;
  const MeetingsTab({super.key, required this.project});

  @override
  State<MeetingsTab> createState() => _MeetingsTabState();
}

class _MeetingsTabState extends State<MeetingsTab> {
  late final Stream<List<MeetingModel>> _meetingsStream;
  Map<String, String> _memberNames = {};

  @override
  void initState() {
    super.initState();
    _meetingsStream = context
        .read<CollaborationProvider>()
        .meetingsStream(widget.project.id);
    _loadMemberNames();
  }

  Future<void> _loadMemberNames() async {
    final Map<String, String> result = {};
    for (final uid in widget.project.members) {
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

  Future<void> _showScheduleDialog() async {
    final titleCtrl = TextEditingController();
    DateTime? pickedDate;
    TimeOfDay? pickedTime;
    final selectedUids = <String>{};

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: context.mt.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md)),
          title: Text('Schedule Meeting',
              style: GoogleFonts.sora(
                  color: context.mt.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DlgLabel('Title'),
                const SizedBox(height: 6),
                _DlgField(controller: titleCtrl, hint: 'Meeting title...'),
                const SizedBox(height: 14),
                _DlgLabel('Date'),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate:
                          DateTime.now().add(const Duration(days: 1)),
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
                _DlgLabel('Invite Members'),
                const SizedBox(height: 8),
                ..._memberNames.entries.map((e) => CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.primary,
                      checkColor: Colors.white,
                      title: Text(e.value,
                          style: GoogleFonts.sora(
                              color: context.mt.textPrimary, fontSize: 13)),
                      value: selectedUids.contains(e.key),
                      onChanged: (v) => setDlg(() {
                        if (v == true) {
                          selectedUids.add(e.key);
                        } else {
                          selectedUids.remove(e.key);
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
                  style:
                      GoogleFonts.sora(color: context.mt.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty || pickedDate == null) {
                  return;
                }
                final dt = pickedTime == null
                    ? pickedDate!
                    : DateTime(
                        pickedDate!.year,
                        pickedDate!.month,
                        pickedDate!.day,
                        pickedTime!.hour,
                        pickedTime!.minute,
                      );
                await context
                    .read<CollaborationProvider>()
                    .addMeeting(MeetingModel(
                      id: '',
                      projectId: widget.project.id,
                      title: titleCtrl.text.trim(),
                      date: dt,
                      link: '',
                      participants: selectedUids.toList(),
                    ));
                if (ctx.mounted) Navigator.pop(ctx);
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MeetingModel>>(
      stream: _meetingsStream,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        final now = DateTime.now();
        final all = snap.data ?? [];
        final upcoming =
            all.where((m) => m.date.isAfter(now)).toList();
        final past =
            all.where((m) => !m.date.isAfter(now)).toList().reversed.toList();

        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [
                _SectionLabel('UPCOMING'),
                const SizedBox(height: 12),
                if (upcoming.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text('No upcoming meetings',
                        style: GoogleFonts.sora(
                            color: context.mt.textSecondary, fontSize: 13)),
                  )
                else
                  ...upcoming.map((m) => _UpcomingCard(
                        meeting: m,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.meetingRoom,
                          arguments: widget.project,
                        ),
                      )),
                const SizedBox(height: 24),
                _SectionLabel('PAST'),
                const SizedBox(height: 12),
                if (past.isEmpty)
                  Text('No past meetings',
                      style: GoogleFonts.sora(
                          color: context.mt.textSecondary, fontSize: 13))
                else
                  ...past.map((m) => _PastRow(
                        meeting: m,
                        memberNames: _memberNames,
                      )),
              ],
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                heroTag: 'schedule_meeting',
                onPressed: _showScheduleDialog,
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text('Schedule Meeting',
                    style: GoogleFonts.sora(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Upcoming card ─────────────────────────────────────────────────────────────
class _UpcomingCard extends StatelessWidget {
  final MeetingModel meeting;
  final VoidCallback onTap;
  const _UpcomingCard({required this.meeting, required this.onTap});

  String _badge() {
    final now = DateTime.now();
    final diff =
        meeting.date.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return 'In $diff days';
  }

  Color _badgeColor() {
    final now = DateTime.now();
    final diff =
        meeting.date.difference(DateTime(now.year, now.month, now.day)).inDays;
    return diff <= 1 ? AppColors.inProgressOrange : AppColors.primary;
  }

  String _formatDate(DateTime d) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  String _formatTime(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final period = d.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                  Text(meeting.title,
                      style: GoogleFonts.sora(
                          color: context.mt.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(meeting.date)} • ${_formatTime(meeting.date)}',
                    style: GoogleFonts.sora(
                        color: context.mt.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _badgeColor().withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(_badge(),
                  style: GoogleFonts.sora(
                      color: _badgeColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Past row ──────────────────────────────────────────────────────────────────
class _PastRow extends StatelessWidget {
  final MeetingModel meeting;
  final Map<String, String> memberNames;
  const _PastRow({required this.meeting, required this.memberNames});

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

  String _formatShort(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final show = meeting.participants.length > 4
        ? 4
        : meeting.participants.length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meeting.title,
                    style: GoogleFonts.sora(
                        color: context.mt.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(_formatShort(meeting.date),
                    style: GoogleFonts.sora(
                        color: context.mt.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          if (show > 0)
            SizedBox(
              width: show * 18.0 + 4,
              height: 28,
              child: Stack(
                children: List.generate(show, (i) => Positioned(
                      left: i * 18.0,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _avatarColor(i),
                          border: Border.all(
                              color: context.mt.background, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            (memberNames[meeting.participants[i]] ?? '?')[0]
                                .toUpperCase(),
                            style: GoogleFonts.sora(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700),
                          ),
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
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.sora(
          color: context.mt.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4));
}

// ── Dialog helpers ────────────────────────────────────────────────────────────
class _DlgLabel extends StatelessWidget {
  final String text;
  const _DlgLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.sora(
          color: context.mt.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600));
}

class _DlgField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _DlgField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        style: GoogleFonts.sora(color: context.mt.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.sora(color: context.mt.textSecondary, fontSize: 13),
          filled: true,
          fillColor: context.mt.background,
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
          color: context.mt.background,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Row(
          children: [
            Icon(icon, color: context.mt.textSecondary, size: 16),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.sora(
                    color: context.mt.textPrimary, fontSize: 13)),
          ],
        ),
      );
}
