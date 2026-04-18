import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/collaboration_provider.dart';

class MeetingRoomScreen extends StatefulWidget {
  const MeetingRoomScreen({super.key});

  @override
  State<MeetingRoomScreen> createState() => _MeetingRoomScreenState();
}

class _MeetingRoomScreenState extends State<MeetingRoomScreen> {
  // Timer
  late Timer _timer;
  int _seconds = 0;

  // Controls state
  bool _micOn = false;
  bool _camOn = true;
  bool _sharing = true;
  bool _handRaised = false;

  // Demo participants
  final _participants = [
    _Participant('Ahmed', true, true),   // active speaker
    _Participant('Sarah', false, false),
    _Participant('David', false, false),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _timerLabel {
    final h = (_seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((_seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettingsProvider>();
    final project =
        ModalRoute.of(context)!.settings.arguments as ProjectModel?;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Row(
          children: [
            const Icon(Icons.videocam_off_outlined,
                color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 8),
            Text(
              'Project Sync • ML Active',
              style: GoogleFonts.sora(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Status bar ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                // "Ahmed is sharing" pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Ahmed is sharing',
                        style: GoogleFonts.sora(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Timer
                Text(
                  _timerLabel,
                  style: GoogleFonts.sora(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),

          // ── Screen share area ──────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.4), width: 1.5),
                ),
                child: Column(
                  children: [
                    // File name bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                      child: Row(
                        children: [
                          const Icon(Icons.insert_drive_file_outlined,
                              color: AppColors.textSecondary, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'Figma — wireframe.fig',
                            style: GoogleFonts.sora(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Shared screen grid
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                        child: _SharedScreenGrid(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Participant strip ──────────────────────────────────────
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                ..._participants.map((p) => _ParticipantTile(p: p)),
                // +12 others
                _OthersTile(count: 12),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Control bar ────────────────────────────────────────────
          _ControlBar(
            micOn: _micOn,
            camOn: _camOn,
            sharing: _sharing,
            handRaised: _handRaised,
            onMic: () => setState(() => _micOn = !_micOn),
            onCam: () => setState(() => _camOn = !_camOn),
            onShare: () => setState(() => _sharing = !_sharing),
            onHand: () => setState(() => _handRaised = !_handRaised),
            onEnd: () => Navigator.pop(context),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Shared screen grid ────────────────────────────────────────────────────────
class _SharedScreenGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _ScreenBlock()),
              const SizedBox(width: 6),
              Expanded(child: _ScreenBlock()),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    _ScreenBlock(),
                    // Cursor label
                    Positioned(
                      bottom: 8,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.near_me_rounded,
                                color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'Ahmed',
                              style: GoogleFonts.sora(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScreenBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
    );
  }
}

// ── Participant tile ──────────────────────────────────────────────────────────
class _ParticipantTile extends StatelessWidget {
  final _Participant p;
  const _ParticipantTile({required this.p});

  Color _avatarColor(String name) {
    const colors = [
      AppColors.primary,
      Color(0xFFB0B0B0),
      Color(0xFF707070),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      margin: const EdgeInsets.only(right: 10),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  color: _avatarColor(p.name),
                  border: p.isActive
                      ? Border.all(color: AppColors.success, width: 2.5)
                      : null,
                ),
                child: Center(
                  child: Text(
                    p.name[0].toUpperCase(),
                    style: GoogleFonts.sora(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (p.isActive)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            p.name,
            style: GoogleFonts.sora(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _OthersTile extends StatelessWidget {
  final int count;
  const _OthersTile({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.sm),
              color: AppColors.surface,
            ),
            child: Center(
              child: Text(
                '+$count',
                style: GoogleFonts.sora(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Others',
            style: GoogleFonts.sora(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Control bar ───────────────────────────────────────────────────────────────
class _ControlBar extends StatelessWidget {
  final bool micOn, camOn, sharing, handRaised;
  final VoidCallback onMic, onCam, onShare, onHand, onEnd;

  const _ControlBar({
    required this.micOn,
    required this.camOn,
    required this.sharing,
    required this.handRaised,
    required this.onMic,
    required this.onCam,
    required this.onShare,
    required this.onHand,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Mic
          _CtrlBtn(
            icon: micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
            active: micOn,
            onTap: onMic,
          ),
          // Camera
          _CtrlBtn(
            icon: camOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
            active: camOn,
            onTap: onCam,
          ),
          // Share — pill style
          GestureDetector(
            onTap: onShare,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: sharing
                    ? AppColors.primary.withOpacity(0.25)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: sharing
                    ? Border.all(color: AppColors.primary, width: 1.5)
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.screen_share_rounded,
                    color: sharing
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'SHARING',
                    style: GoogleFonts.sora(
                      color: sharing
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Hand raise
          _CtrlBtn(
            icon: Icons.back_hand_outlined,
            active: handRaised,
            activeColor: AppColors.inProgressOrange,
            onTap: onHand,
          ),
          // End call
          GestureDetector(
            onTap: onEnd,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: const Icon(Icons.call_end_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _CtrlBtn({
    required this.icon,
    required this.active,
    required this.onTap,
    this.activeColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: active
              ? activeColor.withOpacity(0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Icon(
          icon,
          color: active ? activeColor : AppColors.textSecondary,
          size: 22,
        ),
      ),
    );
  }
}

// ── Data ──────────────────────────────────────────────────────────────────────
class _Participant {
  final String name;
  final bool isActive;
  final bool isSpeaking;
  _Participant(this.name, this.isActive, this.isSpeaking);
}
