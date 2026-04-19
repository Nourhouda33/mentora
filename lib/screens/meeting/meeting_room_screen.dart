
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/collaboration_provider.dart';

const _taskKeywords = [
  'créer', 'faire', 'ajouter', 'implémenter', 'développer', 'corriger',
  'create', 'make', 'add', 'implement', 'develop', 'fix', 'build', 'write',
  'il faut', 'on doit', 'we need', 'we should', 'todo', 'task',
];
const _meetingKeywords = [
  'meeting', 'réunion', 'demain', 'tomorrow', 'lundi', 'mardi', 'mercredi',
  'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'schedule',
  'planifier', 'rendez-vous',
];

class MeetingRoomScreen extends StatefulWidget {
  const MeetingRoomScreen({super.key});

  @override
  State<MeetingRoomScreen> createState() => _MeetingRoomScreenState();
}

class _MeetingRoomScreenState extends State<MeetingRoomScreen> {
  late Timer _timer;
  int _seconds = 0;
  bool _starting = false;
  bool _chatOpen = false;

  bool _micOn = true;
  bool _camOn = true;

  final _localRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  bool _rendererInit = false;

  final _chatCtrl = TextEditingController();
  final _chatScroll = ScrollController();

  String? _aiSuggestion;
  String? _aiSuggestionType;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get _displayName {
    final u = FirebaseAuth.instance.currentUser;
    return u?.displayName ?? u?.email?.split('@').first ?? 'User';
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
    _initRenderer();
  }

  Future<void> _initRenderer() async {
    await _localRenderer.initialize();
    if (mounted) setState(() => _rendererInit = true);
  }

  Future<void> _startCamera() async {
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'video': {'facingMode': 'user'},
        'audio': true,
      });
      _localRenderer.srcObject = _localStream;
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _stopCamera() async {
    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream = null;
    _localRenderer.srcObject = null;
    if (mounted) setState(() {});
  }

  Future<void> _toggleMic() async {
    final audio = _localStream?.getAudioTracks();
    if (audio != null && audio.isNotEmpty) {
      final newState = !_micOn;
      audio.first.enabled = newState;
      setState(() => _micOn = newState);
      final project = ModalRoute.of(context)!.settings.arguments as ProjectModel?;
      if (project != null) {
        await context.read<CollaborationProvider>().updateParticipantState(
              projectId: project.id, micOn: newState, camOn: _camOn);
      }
    }
  }

  Future<void> _toggleCam() async {
    final video = _localStream?.getVideoTracks();
    if (video != null && video.isNotEmpty) {
      final newState = !_camOn;
      video.first.enabled = newState;
      setState(() => _camOn = newState);
      final project = ModalRoute.of(context)!.settings.arguments as ProjectModel?;
      if (project != null) {
        await context.read<CollaborationProvider>().updateParticipantState(
              projectId: project.id, micOn: _micOn, camOn: newState);
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _stopCamera();
    _localRenderer.dispose();
    _chatCtrl.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  String get _timerLabel {
    final h = (_seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((_seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _startMeeting(ProjectModel project) async {
    setState(() => _starting = true);
    await _startCamera();
    await context.read<CollaborationProvider>().startLiveMeeting(
          projectId: project.id,
          hostName: _displayName,
          meetingTitle: '${project.name} — Live',
        );
    if (mounted) setState(() => _starting = false);
  }

  Future<void> _joinMeeting(ProjectModel project) async {
    await _startCamera();
    await context.read<CollaborationProvider>().joinLiveMeeting(
          projectId: project.id,
          participantName: _displayName,
          micOn: _micOn,
          camOn: _camOn,
        );
  }

  Future<void> _endMeeting(ProjectModel project, bool isHost) async {
    await _stopCamera();
    if (isHost) {
      await _showEndSummaryDialog(project);
      await context.read<CollaborationProvider>().endLiveMeeting(project.id);
      await context.read<CollaborationProvider>().clearMeetingChat(project.id);
    } else {
      await context.read<CollaborationProvider>().leaveLiveMeeting(project.id);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _showEndSummaryDialog(ProjectModel project) async {
    final snap = await FirebaseFirestore.instance
        .collection('projects')
        .doc(project.id)
        .get();
    final live = (snap.data() ?? {})['liveMeeting'] as Map<String, dynamic>?;
    final participants =
        (live?['participants'] as Map<String, dynamic>? ?? {});
    final names = participants.values
        .map((v) => (v as Map)['name']?.toString() ?? '?')
        .toList();

    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.mt.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md)),
        title: Text('Meeting Summary',
            style: GoogleFonts.sora(
                color: context.mt.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duration: $_timerLabel',
                style: GoogleFonts.sora(
                    color: context.mt.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            Text('Participants (${names.length}):',
                style: GoogleFonts.sora(
                    color: context.mt.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            ...names.map((n) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(n,
                          style: GoogleFonts.sora(
                              color: context.mt.textPrimary, fontSize: 13)),
                    ],
                  ),
                )),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.sm)),
            ),
            child: Text('Close',
                style: GoogleFonts.sora(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _analyzeMessage(String text, ProjectModel project) {
    final lower = text.toLowerCase();
    final isTask = _taskKeywords.any((k) => lower.contains(k));
    final isMeeting = _meetingKeywords.any((k) => lower.contains(k));
    if (isTask || isMeeting) {
      setState(() {
        _aiSuggestion = text.length > 50 ? '${text.substring(0, 50)}...' : text;
        _aiSuggestionType = isTask ? 'task' : 'meeting';
      });
    }
  }

  Future<void> _sendChatMessage(ProjectModel project) async {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;
    _chatCtrl.clear();
    await context
        .read<CollaborationProvider>()
        .sendMeetingChatMessage(projectId: project.id, text: text);
    _analyzeMessage(text, project);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScroll.hasClients) {
        _chatScroll.animateTo(_chatScroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }

  Future<void> _saveAiSuggestion(ProjectModel project) async {
    if (_aiSuggestion == null) return;
    if (_aiSuggestionType == 'task') {
      await context.read<CollaborationProvider>().addTaskFromSuggestion(
            projectId: project.id,
            title: _aiSuggestion!,
          );
    }
    setState(() { _aiSuggestion = null; _aiSuggestionType = null; });
  }

  @override
  Widget build(BuildContext context) {
    final project =
        ModalRoute.of(context)!.settings.arguments as ProjectModel?;
    if (project == null) {
      return Scaffold(
          backgroundColor: context.mt.background,
          body: const Center(child: Text('No project')));
    }

    return StreamBuilder<Map<String, dynamic>?>(
      stream: context
          .read<CollaborationProvider>()
          .liveMeetingStream(project.id),
      builder: (ctx, snap) {
        final live = snap.data;
        final isLive = live != null && live['active'] == true;
        final isHost = live?['hostUid'] == _uid;
        final hostName = live?['hostName'] ?? '';
        final meetingTitle = live?['title'] ?? '${project.name} — Live';
        final participants =
            (live?['participants'] as Map<String, dynamic>? ?? {});
        final iAmIn = participants.containsKey(_uid);

        if (isLive && !iAmIn && !_starting) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _joinMeeting(project));
        }

        return Scaffold(
          backgroundColor: context.mt.background,
          appBar: AppBar(
            backgroundColor: context.mt.background,
            elevation: 0,
            iconTheme: IconThemeData(color: context.mt.textPrimary),
            title: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isLive
                        ? AppColors.success
                        : AppColors.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isLive ? meetingTitle : 'Meeting Room',
                    style: GoogleFonts.sora(
                        color: context.mt.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isLive)
                  Text(_timerLabel,
                      style: GoogleFonts.sora(
                          color: context.mt.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [
                            FontFeature.tabularFigures()
                          ])),
              ],
            ),
            actions: [
              if (isLive)
                IconButton(
                  icon: Icon(
                    _chatOpen
                        ? Icons.chat_bubble_rounded
                        : Icons.chat_bubble_outline_rounded,
                    color: _chatOpen
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  onPressed: () =>
                      setState(() => _chatOpen = !_chatOpen),
                ),
            ],
          ),
          body: isLive
              ? _chatOpen
                  ? _MeetingChatPanel(
                      project: project,
                      chatCtrl: _chatCtrl,
                      chatScroll: _chatScroll,
                      aiSuggestion: _aiSuggestion,
                      aiSuggestionType: _aiSuggestionType,
                      onSend: () => _sendChatMessage(project),
                      onSaveAi: () => _saveAiSuggestion(project),
                      onDismissAi: () => setState(
                          () { _aiSuggestion = null; _aiSuggestionType = null; }),
                    )
                  : _LiveBody(
                      project: project,
                      hostName: hostName,
                      isHost: isHost,
                      participants: participants,
                      localRenderer: _localRenderer,
                      rendererInit: _rendererInit,
                      localStreamActive: _localStream != null,
                      micOn: _micOn,
                      camOn: _camOn,
                      onMic: _toggleMic,
                      onCam: _toggleCam,
                      onEnd: () => _endMeeting(project, isHost),
                    )
              : _WaitingBody(
                  project: project,
                  starting: _starting,
                  onStart: () => _startMeeting(project),
                ),
        );
      },
    );
  }
}

// ── Waiting lobby ─────────────────────────────────────────────────────────────
class _WaitingBody extends StatelessWidget {
  final ProjectModel project;
  final bool starting;
  final VoidCallback onStart;
  const _WaitingBody({required this.project, required this.starting, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 2),
              ),
              child: const Icon(Icons.videocam_rounded, color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 24),
            Text(project.name,
                style: GoogleFonts.sora(color: context.mt.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('No active meeting.\nStart one to notify all members.',
                style: GoogleFonts.sora(color: context.mt.textSecondary, fontSize: 13, height: 1.6),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton.icon(
                onPressed: starting ? null : onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                  elevation: 0,
                ),
                icon: starting
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                label: Text(starting ? 'Starting...' : 'Start Meeting',
                    style: GoogleFonts.sora(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Live meeting body ─────────────────────────────────────────────────────────
class _LiveBody extends StatelessWidget {
  final ProjectModel project;
  final String hostName;
  final bool isHost;
  final Map<String, dynamic> participants;
  final RTCVideoRenderer localRenderer;
  final bool rendererInit;
  final bool localStreamActive;
  final bool micOn, camOn;
  final VoidCallback onMic, onCam, onEnd;

  const _LiveBody({
    required this.project, required this.hostName, required this.isHost,
    required this.participants, required this.localRenderer,
    required this.rendererInit, required this.localStreamActive,
    required this.micOn, required this.camOn,
    required this.onMic, required this.onCam, required this.onEnd,
  });

  Color _avatarColor(String uid) {
    const colors = [AppColors.primary, Color(0xFFFF7B7B), AppColors.success,
        AppColors.inProgressOrange, AppColors.accent];
    return colors[uid.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final participantList = participants.entries.toList();

    return Column(
      children: [
        // ── Live indicator ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.success.withOpacity(0.4)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 6, height: 6,
                      decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('$hostName is hosting',
                      style: GoogleFonts.sora(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w500)),
                ]),
              ),
              const Spacer(),
              Text('${participantList.length} in call',
                  style: GoogleFonts.sora(color: context.mt.textSecondary, fontSize: 12)),
            ],
          ),
        ),

        // ── Local camera view ────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Stack(fit: StackFit.expand, children: [
                Container(color: AppColors.surface),
                if (rendererInit && localStreamActive && camOn)
                  RTCVideoView(localRenderer, mirror: true,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
                else
                  Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _avatarColor(uid),
                          border: Border.all(color: AppColors.success, width: 3),
                        ),
                        child: Center(
                          child: Text(
                            (FirebaseAuth.instance.currentUser?.displayName ?? 'U')[0].toUpperCase(),
                            style: GoogleFonts.sora(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(camOn ? 'Camera starting...' : 'Camera off',
                          style: GoogleFonts.sora(color: context.mt.textSecondary, fontSize: 12)),
                    ]),
                  ),
                // Mic indicator
                Positioned(bottom: 10, left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                          color: micOn ? AppColors.success : AppColors.error, size: 14),
                      const SizedBox(width: 4),
                      Text('You', style: GoogleFonts.sora(color: Colors.white, fontSize: 11)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // ── Participants strip ───────────────────────────────────────
        SizedBox(
          height: 88,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: participantList.length,
            itemBuilder: (ctx, i) {
              final pUid = participantList[i].key;
              final pData = participantList[i].value as Map<String, dynamic>;
              final name = pData['name']?.toString() ?? '?';
              final pMic = pData['micOn'] == true;
              final pCam = pData['camOn'] == true;
              final isMe = pUid == uid;
              return Container(
                width: 70, margin: const EdgeInsets.only(right: 10),
                child: Column(children: [
                  Stack(children: [
                    Container(
                      width: 58, height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        color: _avatarColor(pUid),
                        border: isMe ? Border.all(color: AppColors.primary, width: 2) : null,
                      ),
                      child: Center(
                        child: Text(name[0].toUpperCase(),
                            style: GoogleFonts.sora(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    Positioned(bottom: 3, right: 3,
                      child: Container(
                        width: 18, height: 18,
                        decoration: BoxDecoration(
                          color: context.mt.background,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surface, width: 1),
                        ),
                        child: Icon(
                          pMic ? Icons.mic_rounded : Icons.mic_off_rounded,
                          color: pMic ? AppColors.success : AppColors.error, size: 11,
                        ),
                      ),
                    ),
                    if (!pCam)
                      Positioned(top: 3, right: 3,
                        child: Container(
                          width: 16, height: 16,
                          decoration: BoxDecoration(color: AppColors.error.withOpacity(0.9), shape: BoxShape.circle),
                          child: const Icon(Icons.videocam_off_rounded, color: Colors.white, size: 10),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 4),
                  Text(isMe ? 'You' : name,
                      style: GoogleFonts.sora(color: context.mt.textSecondary, fontSize: 10),
                      overflow: TextOverflow.ellipsis),
                ]),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // ── Controls ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CtrlBtn(icon: micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                  active: micOn, onTap: onMic),
              _CtrlBtn(icon: camOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                  active: camOn, onTap: onCam),
              GestureDetector(
                onTap: onEnd,
                child: Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(AppRadii.md)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.call_end_rounded, color: Colors.white, size: 22),
                    Text(isHost ? 'End' : 'Leave',
                        style: GoogleFonts.sora(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Meeting chat panel ────────────────────────────────────────────────────────
class _MeetingChatPanel extends StatelessWidget {
  final ProjectModel project;
  final TextEditingController chatCtrl;
  final ScrollController chatScroll;
  final String? aiSuggestion;
  final String? aiSuggestionType;
  final VoidCallback onSend;
  final VoidCallback onSaveAi;
  final VoidCallback onDismissAi;

  const _MeetingChatPanel({
    required this.project, required this.chatCtrl, required this.chatScroll,
    required this.aiSuggestion, required this.aiSuggestionType,
    required this.onSend, required this.onSaveAi, required this.onDismissAi,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: context.read<CollaborationProvider>().meetingChatStream(project.id),
            builder: (ctx, snap) {
              final msgs = snap.data ?? [];
              return ListView.builder(
                controller: chatScroll,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                itemCount: msgs.length,
                itemBuilder: (ctx, i) {
                  final m = msgs[i];
                  final isMe = m['senderUid'] == uid;
                  final name = m['senderName']?.toString() ?? '?';
                  final text = m['text']?.toString() ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMe) ...[
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
                            child: Center(child: Text(name[0].toUpperCase(),
                                style: GoogleFonts.sora(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Text(name, style: GoogleFonts.sora(color: context.mt.textSecondary, fontSize: 11)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isMe ? AppColors.primary.withOpacity(0.25) : AppColors.surface,
                                  borderRadius: BorderRadius.circular(AppRadii.sm),
                                ),
                                child: Text(text,
                                    style: GoogleFonts.sora(color: context.mt.textPrimary, fontSize: 13, height: 1.4)),
                              ),
                            ],
                          ),
                        ),
                        if (isMe) const SizedBox(width: 8),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),

        // AI suggestion banner
        if (aiSuggestion != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2640),
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(color: AppColors.primary.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(width: 7, height: 7,
                      decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('AI DETECTED — ${aiSuggestionType == 'task' ? 'TASK' : 'MEETING'}',
                      style: GoogleFonts.sora(color: AppColors.primary, fontSize: 9,
                          fontWeight: FontWeight.w700, letterSpacing: 1)),
                  const Spacer(),
                  GestureDetector(onTap: onDismissAi,
                      child: Icon(Icons.close, color: context.mt.textSecondary, size: 16)),
                ]),
                const SizedBox(height: 6),
                Text('"$aiSuggestion"',
                    style: GoogleFonts.sora(color: context.mt.textSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onSaveAi,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
                        elevation: 0,
                      ),
                      child: Text('Save as ${aiSuggestionType == 'task' ? 'Task' : 'Meeting'}',
                          style: GoogleFonts.sora(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDismissAi,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
                      ),
                      child: Text('Ignore', style: GoogleFonts.sora(color: context.mt.textSecondary, fontSize: 12)),
                    ),
                  ),
                ]),
              ],
            ),
          ),

        // Input
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          decoration: BoxDecoration(
            color: context.mt.background,
            border: Border(top: BorderSide(color: Color(0xFF252D40), width: 1)),
          ),
          child: Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                child: TextField(
                  controller: chatCtrl,
                  style: GoogleFonts.sora(color: context.mt.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Message in meeting...',
                    hintStyle: GoogleFonts.sora(color: context.mt.textSecondary, fontSize: 13),
                    border: InputBorder.none, isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onSend,
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadii.md)),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

// ── Control button ────────────────────────────────────────────────────────────
class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _CtrlBtn({required this.icon, required this.active, required this.onTap,
      this.activeColor = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: active ? activeColor.withOpacity(0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: active ? Border.all(color: activeColor.withOpacity(0.4)) : null,
        ),
        child: Icon(icon, color: active ? activeColor : AppColors.textSecondary, size: 24),
      ),
    );
  }
}
