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

const _aiKeywords = [
  'deadline', 'review', 'finalize', 'standup', 'wireframe',
  'sync', 'meeting', 'check', 'update', 'finish', 'complete',
];

class ChatTab extends StatefulWidget {
  final ProjectModel project;
  const ChatTab({super.key, required this.project});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _picker = ImagePicker();

  String? _aiSuggestionText;
  bool _showAiCard = false;

  late final Stream<List<MessageModel>> _messagesStream;

  String get _currentUser {
    final u = FirebaseAuth.instance.currentUser;
    return u?.displayName ?? u?.email?.split('@').first ?? 'User';
  }

  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
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

  void _sendText() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    context.read<CollaborationProvider>().sendTextMessage(
          projectId: widget.project.id,
          sender: _currentUser,
          text: text,
        );

    final lower = text.toLowerCase();
    final matched = _aiKeywords.firstWhere(
      (k) => lower.contains(k),
      orElse: () => '',
    );
    if (matched.isNotEmpty) {
      final suggestion =
          text.length > 40 ? '${text.substring(0, 40)}...' : text;
      setState(() {
        _aiSuggestionText = suggestion;
        _showAiCard = true;
      });
    }

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

  void _showCameraSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
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
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'What do you want to do?',
              style: GoogleFonts.sora(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _SheetOption(
              icon: Icons.picture_as_pdf_rounded,
              label: 'Scan & Convert PDF',
              onTap: () {
                Navigator.pop(context);
                _scanAndConvertPdf();
              },
            ),
            const SizedBox(height: 10),
            _SheetOption(
              icon: Icons.image_outlined,
              label: 'Send as Photo',
              onTap: () {
                Navigator.pop(context);
                _sendAsPhoto();
              },
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
      pdf.addPage(pw.Page(
        build: (ctx) => pw.Center(child: pw.Image(pdfImage)),
      ));
      final dir = await getTemporaryDirectory();
      final pdfPath =
          '${dir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final pdfFile = File(pdfPath);
      await pdfFile.writeAsBytes(await pdf.save());
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la conversion PDF',
              style: GoogleFonts.sora(color: Colors.white)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _sendAsPhoto() async {
    final xfile = await _picker.pickImage(source: ImageSource.camera);
    if (xfile == null) return;
    if (!mounted) return;
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
    if (file.path == null) return;
    if (!mounted) return;
    context.read<CollaborationProvider>().sendFileMessage(
          projectId: widget.project.id,
          sender: _currentUser,
          fileName: file.name,
          filePath: file.path!,
          type: MessageType.file,
        );
    _scrollToBottom();
  }

  void _addToList() {
    if (_aiSuggestionText == null) return;
    context.read<CollaborationProvider>().addTaskFromSuggestion(
          projectId: widget.project.id,
          title: _aiSuggestionText!,
        );
    setState(() => _showAiCard = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tâche ajoutée',
            style: GoogleFonts.sora(color: Colors.white)),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<MessageModel>>(
            stream: _messagesStream,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting &&
                  !snap.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary));
              }
              final messages = snap.data ?? [];
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _scrollToBottom());
              return ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                itemCount: messages.length + (_showAiCard ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (_showAiCard && i == messages.length) {
                    return _AiSuggestionCard(
                      suggestion: _aiSuggestionText ?? '',
                      onAddToList: _addToList,
                      onIgnore: () => setState(() => _showAiCard = false),
                    );
                  }
                  final msg = messages[i];
                  if (_showAiCard &&
                      i == messages.length - 1 &&
                      messages.length > 1) {
                    return Column(
                      children: [
                        _MessageBubble(
                            message: msg, currentUid: _currentUid),
                        _AiSuggestionCard(
                          suggestion: _aiSuggestionText ?? '',
                          onAddToList: _addToList,
                          onIgnore: () =>
                              setState(() => _showAiCard = false),
                        ),
                      ],
                    );
                  }
                  return _MessageBubble(
                      message: msg, currentUid: _currentUid);
                },
              );
            },
          ),
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
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '• ${_formatTime(message.timestamp)}',
                style: GoogleFonts.sora(
                  color: AppColors.textSecondary,
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
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image,
                            color: AppColors.textSecondary),
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
                          color: AppColors.textPrimary,
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
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Added to calendar by ${message.sender}',
                  style: GoogleFonts.sora(
                    color: AppColors.textSecondary,
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

// ── AI Suggestion Card ────────────────────────────────────────────────────────
class _AiSuggestionCard extends StatelessWidget {
  final String suggestion;
  final VoidCallback onAddToList;
  final VoidCallback onIgnore;

  const _AiSuggestionCard({
    required this.suggestion,
    required this.onAddToList,
    required this.onIgnore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2640),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
            color: AppColors.primary.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'AI SUGGESTION',
                style: GoogleFonts.sora(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Icon(Icons.auto_awesome_rounded,
                  color: AppColors.primary.withOpacity(0.7), size: 16),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'New Task Detected',
            style: GoogleFonts.sora(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '"$suggestion"',
            style: GoogleFonts.sora(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onAddToList,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                  ),
                  child: Text(
                    'Add to List',
                    style: GoogleFonts.sora(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onIgnore,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(
                        color: AppColors.textSecondary.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    'Ignore',
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
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
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
            top: BorderSide(color: Color(0xFF252D40), width: 1)),
      ),
      child: Row(
        children: [
          // Camera icon
          IconButton(
            onPressed: onCamera,
            icon: const Icon(Icons.camera_alt_outlined,
                color: AppColors.textSecondary, size: 22),
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
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Message Project Chat...',
                        hintStyle: GoogleFonts.sora(
                          color: AppColors.textSecondary,
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
                    child: const Icon(Icons.attach_file_rounded,
                        color: AppColors.textSecondary, size: 20),
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
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.sora(
                color: AppColors.textPrimary,
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
