import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/collaboration_provider.dart';

class NewProjectScreen extends StatefulWidget {
  const NewProjectScreen({super.key});

  @override
  State<NewProjectScreen> createState() => _NewProjectScreenState();
}

class _NewProjectScreenState extends State<NewProjectScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _deadline;
  bool _loading = false;

  // Projet créé — affiché après création
  ProjectModel? _createdProject;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Date picker ────────────────────────────────────────────────────────────
  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  // ── Create project ─────────────────────────────────────────────────────────
  void _create() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final project = await context.read<CollaborationProvider>().createProject(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          deadline: _deadline,
        );
    if (!mounted) return;
    setState(() {
      _createdProject = project;
      _loading = false;
    });
  }

  // ── Copy to clipboard ──────────────────────────────────────────────────────
  void _copyCode() {
    if (_createdProject == null) return;
    Clipboard.setData(ClipboardData(text: _createdProject!.inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Code copié : ${_createdProject!.inviteCode}',
          style: GoogleFonts.sora(color: Colors.white),
        ),
        backgroundColor: AppColors.surface,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyLink() {
    if (_createdProject == null) return;
    Clipboard.setData(ClipboardData(text: _createdProject!.joinLink));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Lien copié',
          style: GoogleFonts.sora(color: Colors.white),
        ),
        backgroundColor: AppColors.surface,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          s.t('new_project'),
          style: GoogleFonts.sora(
            color: AppColors.primary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── PROJECT NAME ─────────────────────────────────────────────────
            _SectionLabel('PROJECT NAME'),
            const SizedBox(height: 8),
            _InputField(
              controller: _nameCtrl,
              hint: 'Enter project title...',
              maxLines: 1,
            ),
            const SizedBox(height: 20),

            // ── DESCRIPTION ──────────────────────────────────────────────────
            _SectionLabel('DESCRIPTION'),
            const SizedBox(height: 8),
            _InputField(
              controller: _descCtrl,
              hint: 'Describe the scope and objectives...',
              maxLines: 4,
            ),
            const SizedBox(height: 20),

            // ── DEADLINE ─────────────────────────────────────────────────────
            _SectionLabel('DEADLINE'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDeadline,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _deadline == null
                            ? 'jj/mm/aaaa'
                            : '${_deadline!.day.toString().padLeft(2, '0')}/'
                                '${_deadline!.month.toString().padLeft(2, '0')}/'
                                '${_deadline!.year}',
                        style: GoogleFonts.sora(
                          color: _deadline == null
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Icon(Icons.calendar_today_outlined,
                        color: AppColors.textSecondary, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── QR CODE CARD (visible après création) ────────────────────────
            if (_createdProject != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Project QR Code',
                          style: GoogleFonts.sora(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // QR code centré
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: _createdProject!.joinLink,
                          version: QrVersions.auto,
                          size: 160,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Boutons PROJECT CODE + Copy link
                    Row(
                      children: [
                        // Code numérique
                        Expanded(
                          child: GestureDetector(
                            onTap: _copyCode,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius:
                                    BorderRadius.circular(AppRadii.sm),
                                border: Border.all(
                                  color: AppColors.textSecondary
                                      .withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'PROJECT CODE',
                                    style: GoogleFonts.sora(
                                      color: AppColors.textSecondary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _createdProject!.inviteCode,
                                    style: GoogleFonts.sora(
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Copy link button
                        Expanded(
                          child: GestureDetector(
                            onTap: _copyLink,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius:
                                    BorderRadius.circular(AppRadii.sm),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.copy_rounded,
                                      color: Colors.white, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    s.t('copy_code'),
                                    style: GoogleFonts.sora(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Aller au projet
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.projectDetail,
                          arguments: _createdProject,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded,
                            size: 18),
                        label: Text(
                          'Aller au projet',
                          style: GoogleFonts.sora(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── CREATE PROJECT button ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _createdProject != null ? null : _create,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor:
                      AppColors.primary.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Create Project',
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

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.sora(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const _InputField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.sora(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.sora(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
