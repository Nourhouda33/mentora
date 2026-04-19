import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/theme.dart';
import '../../../providers/app_settings_provider.dart';
import '../../../providers/collaboration_provider.dart';

// ── AI Detection engine ───────────────────────────────────────────────────────
enum _DetectionType { task, meeting }

class _Detection {
  final _DetectionType type;
  final String text;
  _Detection(this.type, this.text);
}

_Detection? _analyzeText(String text) {
  final lower = text.toLowerCase();

  const taskPatterns = [
    'il faut', 'on doit', 'faut faire', 'faut créer', 'faut ajouter',
    'faut implémenter', 'faut corriger', 'faut développer', 'faut finir',
    'faut terminer', 'faut tester', 'faut vérifier', 'faut mettre',
    'we need to', 'we should', 'we must', 'need to create', 'need to add',
    'need to fix', 'need to build', 'need to implement', 'need to test',
    'todo:', 'to do:', 'task:', 'tâche:', 'action:',
    'créer une', 'créer un', 'ajouter une', 'ajouter un',
    'implémenter', 'développer', 'corriger le', 'corriger la',
    'faire une page', 'faire un', 'faire la', 'faire le',
    'create a', 'create the', 'add a', 'add the', 'fix the', 'fix a',
    'build a', 'build the', 'write a', 'write the', 'update the',
    'refactor', 'migrate', 'deploy', 'configure', 'setup',
  ];

  const meetingPatterns = [
    'réunion', 'meeting', 'appel', 'call', 'visio', 'conférence',
    'on se retrouve', 'on se voit', 'rendez-vous', 'rdv',
    'demain à', 'lundi à', 'mardi à', 'mercredi à', 'jeudi à', 'vendredi à',
    'demain matin', 'demain soir', 'ce soir', 'cet après-midi',
    'tomorrow at', 'monday at', 'tuesday at', 'wednesday at',
    'thursday at', 'friday at', 'let\'s meet', 'let\'s call',
    'schedule a', 'planifier', 'organiser une', 'organiser un',
    'sync demain', 'sync tomorrow', 'daily', 'standup',
  ];

  for (final p in meetingPatterns) {
    if (lower.contains(p)) {
      return _Detection(_DetectionType.meeting, text);
    }
  }
  for (final p in taskPatterns) {
    if (lower.contains(p)) {
      return _Detection(_DetectionType.task, text);
    }
  }
  return null;
}

class ChatTab extends StatefulWidget {
  final ProjectModel project;
  const ChatTab({super.key, required this.project});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

// Persists across widget rebuilds for the lifetime of the app session
// key = projectId, value = last analyzed message id
final Map<String, String> _analyzedIds = {};
// key = projectId, value = set of message ids already handled (saved or ignored)
final Map<String, Set<String>> _handledIds = {};

class _ChatTabState extends State<ChatTab> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _picker = ImagePicker();

  _Detection? _detection;
  String? _detectionMsgId;

  late final Stream<List<MessageModel>> _messagesStream;

  String get _currentUser {
    final u = FirebaseAuth.instance.currentUser;
    return u?.displayName ?? u?.email?.split('@').first ?? 'User';
  }

  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _handledIds.putIfAbsent(widget.project.id, () => {});
    _messagesStream = context
        .read<CollaborationProvider>()
        .messagesStream(widget.project.id);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onNewMessages(List<MessageModel> messages) {
    if (messages.isEmpty) return;
    final last = messages.last;
    if (last.type != MessageType.text) return;

    final pid = widget.project.id;
    // Already analyzed this message
    if (_analyzedIds[pid] == last.id) return;
    // Already handled (saved or ignored) by user
    if (_handledIds[pid]!.contains(last.id)) return;

    _analyzedIds[pid] = last.id;

    final detection = _analyzeText(last.text);
    if (detection != null && mounted) {
      setState(() {
        _detection = detection;
        _detectionMsgId = last.id;
      });
    }
  }

  void _dismissDetection() {
    if (_detectionMsgId != null) {
      _handledIds[widget.project.id]!.add(_detectionMsgId!);
    }
    setState(() { _detection = null; _detectionMsgId = null; });
  }

  void _sendText() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    context.read<CollaborationProvider>().sendTextMessage(
          projectId: widget.project.id,
          sender: _currentUser,
          text: text,
        );
    _msgCtrl.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _saveDetection() async {
    final d = _detection;
    final msgId = _detectionMsgId;
    if (d == null) return;

    // Mark as handled so it never re-triggers
    if (msgId != null) {
      _handledIds[widget.project.id]!.add(msgId);
    }
    setState(() { _detection = null; _detectionMsgId = null; });

    if (d.type == _DetectionType.task) {
      await context.read<CollaborationProvider>().addTaskFromSuggestion(
            projectId: widget.project.id,
            title: d.text.length > 80 ? '${d.text.substring(0, 80)}...' : d.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Task saved',
              style: GoogleFonts.sora(color: Colors.white)),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ));
      }
    } else {
      // Save to meetings tab
      await context.read<CollaborationProvider>().addMeeting(MeetingModel(
            id: '',
            projectId: widget.project.id,
            title: d.text.length > 80 ? '${d.text.substring(0, 80)}...' : d.text,
            date: DateTime.now().add(const Duration(days: 1)),
            link: '',
            participants: [_currentUid],
          ));
      // Also post a calendar card in chat so members see it
      await context.read<CollaborationProvider>().sendCalendarMessage(
            projectId: widget.project.id,
            sender: _currentUser,
            title: d.text.length > 80 ? '${d.text.substring(0, 80)}...' : d.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('📅 Meeting saved to Meetings tab',
              style: GoogleFonts.sora(color: Colors.white)),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ));
      }
    }
  }

  void _showCameraSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.mt.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('What do you want to do?',
                style: GoogleFonts.sora(
                    color: context.mt.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _SheetOption(
              icon: Icons.picture_as_pdf_rounded,
              label: 'Scan & Convert PDF',
              onTap: () { Navigator.pop(context); _scanAndConvertPdf(); },
            ),
            const SizedBox(height: 10),
            _SheetOption(
              icon: Icons.image_outlined,
              label: 'Send as Photo',
              onTap: () { Navigator.pop(context); _sendAsPhoto(); },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanAndConvertPdf() async {
    final xfile = await _picker.pickImage(source: ImageSource.camera);
    if (xfile == null) return;
    try {
      final pdf = pw.Document();
      final imageBytes = await File(xfile.path).readAsBytes();
      final pdfImage = pw.MemoryImage(imageBytes);
      pdf.addPage(pw.Page(build: (ctx) => pw.Center(child: pw.Image(pdfImage))));
      final dir = await getTemporaryDirectory();
      final pdfPath = '${dir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await File(pdfPath).writeAsBytes(await pdf.save());
      if (!mounted) return;
      context.read<CollaborationProvider>().sendFileMessage(
            projectId: widget.project.id,
            sender: _currentUser,
            fileName: 'scan_${DateTime.now().millisecondsSinceEpoch}.pdf',
            filePath: pdfPath,
            type: MessageType.file,
          );
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur lors de la conversion PDF',
            style: GoogleFonts.sora(color: Colors.white)),
        backgroundColor: AppColors.error,
      ));
    }
  }

  Future<void> _sendAsPhoto() async {
    final xfile = await _picker.pickImage(source: ImageSource.camera);
    if (xfile == null || !mounted) return;
    context.read<CollaborationProvider>().sendFileMessage(
          projectId: widget.project.id,
          sender: _currentUser,
          fileName: xfile.name,
          filePath: xfile.path,
          type: MessageType.image,
        );
    _scrollToBottom();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null || !mounted) return;
    context.read<CollaborationProvider>().sendFileMessage(
          projectId: widget.project.id,
          sender: _currentUser,
          fileName: file.name,
          filePath: file.path!,
          type: MessageType.file,
        );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<MessageModel>>(
            stream: _messagesStream,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary));
              }
              final messages = snap.data ?? [];
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _onNewMessages(messages);
                _scrollToBottom();
              });

              return ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                itemCount: messages.length,
                itemBuilder: (ctx, i) =>
                    _MessageBubble(message: messages[i], currentUid: _currentUid),
              );
            },
          ),
        ),

        // ── AI Detection Banner ──────────────────────────────────────
        if (_detection != null)
          _AiDetectionBanner(
            detection: _detection!,
            onSave: _saveDetection,
            onIgnore: _dismissDetection,
          ),

        _InputBar(
          controller: _msgCtrl,
          onSend: _sendText,
          onCamera: _showCameraSheet,
          onAttach: _pickFile,
        ),
      ],
    );
  }
}

// ── Message Bubble ────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final String currentUid;

  const _MessageBubble({required this.message, required this.currentUid});

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    return '$hour12:$m $period';
  }

  Color _avatarColor(String name) {
    final colors = [
      AppColors.primary,
      const Color(0xFFFF7B7B),
      AppColors.success,
      AppColors.inProgressOrange,
      AppColors.accent,
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  void _openFullscreen(BuildContext context, String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white)),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(File(path),
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 64)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calendar message
    if (message.type == MessageType.calendar) {
      return _CalendarCard(message: message);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + name + time
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _avatarColor(message.sender),
                ),
                child: Center(
                  child: Text(
                    message.sender.isNotEmpty
                        ? message.sender[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.sora(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                message.sender,
                style: GoogleFonts.sora(
                  color: context.mt.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '• ${_formatTime(message.timestamp)}',
                style: GoogleFonts.sora(
                  color: context.mt.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Bubble
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(AppRadii.md),
                bottomLeft: Radius.circular(AppRadii.md),
                bottomRight: Radius.circular(AppRadii.md),
              ),
            ),
            child: message.type == MessageType.image &&
                    message.filePath != null
                ? GestureDetector(
                    onTap: () => _openFullscreen(context, message.filePath!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      child: Image.file(
                        File(message.filePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                            Icons.broken_image, color: context.mt.textSecondary),
                      ),
                    ),
                  )
                : message.type == MessageType.file
                    ? GestureDetector(
                        onTap: () {
                          if (message.filePath != null) {
                            OpenFile.open(message.filePath!);
                          }
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.insert_drive_file_outlined,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                message.fileName ?? message.text,
                                style: GoogleFonts.sora(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const Icon(Icons.open_in_new_rounded,
                                color: AppColors.primary, size: 16),
                          ],
                        ),
                      )
                    : Text(
                        message.text,
                        style: GoogleFonts.sora(
                          color: context.mt.textPrimary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Calendar card (event message) ─────────────────────────────────────────────
class _CalendarCard extends StatelessWidget {
  final MessageModel message;
  const _CalendarCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
            color: AppColors.primary.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: const Icon(Icons.calendar_today_rounded,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: GoogleFonts.sora(
                    color: context.mt.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Added to calendar by ${message.sender}',
                  style: GoogleFonts.sora(
                    color: context.mt.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.add_circle_outline,
              color: AppColors.primary, size: 20),
        ],
      ),
    );
  }
}

// ── AI Detection Banner ───────────────────────────────────────────────────────
class _AiDetectionBanner extends StatelessWidget {
  final _Detection detection;
  final VoidCallback onSave;
  final VoidCallback onIgnore;

  const _AiDetectionBanner({
    required this.detection,
    required this.onSave,
    required this.onIgnore,
  });

  @override
  Widget build(BuildContext context) {
    final isTask = detection.type == _DetectionType.task;
    final color = isTask ? AppColors.success : AppColors.primary;
    final icon = isTask ? Icons.task_alt_rounded : Icons.event_rounded;
    final typeLabel = isTask ? 'TASK DETECTED' : 'MEETING DETECTED';
    final actionLabel = isTask ? 'Save Task' : 'Save to Calendar';
    final preview = detection.text.length > 60
        ? '${detection.text.substring(0, 60)}...'
        : detection.text;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(width: 6, height: 6,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text('AI — $typeLabel',
                      style: GoogleFonts.sora(
                          color: color, fontSize: 9,
                          fontWeight: FontWeight.w700, letterSpacing: 1)),
                ]),
                const SizedBox(height: 3),
                Text('"$preview"',
                    style: GoogleFonts.sora(
                        color: context.mt.textSecondary,
                        fontSize: 11,
                        fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              GestureDetector(
                onTap: onSave,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Text(actionLabel,
                      style: GoogleFonts.sora(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onIgnore,
                child: Text('Ignore',
                    style: GoogleFonts.sora(
                        color: context.mt.textSecondary, fontSize: 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Input Bar ─────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onCamera;
  final VoidCallback onAttach;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onCamera,
    required this.onAttach,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: context.mt.background,
        border: Border(
            top: BorderSide(color: Color(0xFF252D40), width: 1)),
      ),
      child: Row(
        children: [
          // Camera icon
          IconButton(
            onPressed: onCamera,
            icon: Icon(Icons.camera_alt_outlined, color: context.mt.textSecondary, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),

          // Text field
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: GoogleFonts.sora(
                        color: context.mt.textPrimary,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Message Project Chat...',
                        hintStyle: GoogleFonts.sora(
                          color: context.mt.textSecondary,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                  // Attach icon
                  GestureDetector(
                    onTap: onAttach,
                    child: Icon(Icons.attach_file_rounded, color: context.mt.textSecondary, size: 20),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom sheet option ───────────────────────────────────────────────────────
class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.mt.background,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.sora(
                color: context.mt.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
