import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme.dart';
import '../../../providers/collaboration_provider.dart';

class InfoTab extends StatelessWidget {
  final ProjectModel project;
  const InfoTab({super.key, required this.project});

  void _copy(BuildContext context, String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$label copied',
          style: GoogleFonts.sora(color: Colors.white)),
      backgroundColor: AppColors.surface,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        // ── QR Code ──────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text('Project QR Code',
                      style: GoogleFonts.sora(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: QrImageView(
                    data: project.joinLink,
                    version: QrVersions.auto,
                    size: 180,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Scan to join this project',
                style: GoogleFonts.sora(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Invite Code ───────────────────────────────────────────────
        _InfoRow(
          label: 'INVITE CODE',
          value: project.inviteCode,
          valueStyle: GoogleFonts.sora(
            color: AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: 6,
          ),
          icon: Icons.tag_rounded,
          onCopy: () => _copy(context, project.inviteCode, 'Invite code'),
        ),
        const SizedBox(height: 12),

        // ── Join Link ─────────────────────────────────────────────────
        _InfoRow(
          label: 'JOIN LINK',
          value: project.joinLink,
          valueStyle: GoogleFonts.sora(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          icon: Icons.link_rounded,
          onCopy: () => _copy(context, project.joinLink, 'Join link'),
        ),
        const SizedBox(height: 24),

        // ── Project Info ──────────────────────────────────────────────
        if (project.description.isNotEmpty) ...[
          _SectionLabel('DESCRIPTION'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Text(project.description,
                style: GoogleFonts.sora(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    height: 1.6)),
          ),
          const SizedBox(height: 16),
        ],

        if (project.deadline != null) ...[
          _SectionLabel('DEADLINE'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Text(
                  '${project.deadline!.day.toString().padLeft(2, '0')}/'
                  '${project.deadline!.month.toString().padLeft(2, '0')}/'
                  '${project.deadline!.year}',
                  style: GoogleFonts.sora(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Info row with copy button ─────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle valueStyle;
  final IconData icon;
  final VoidCallback onCopy;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.valueStyle,
    required this.icon,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 14),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.sora(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2)),
              const Spacer(),
              GestureDetector(
                onTap: onCopy,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.copy_rounded,
                          color: AppColors.primary, size: 13),
                      const SizedBox(width: 4),
                      Text('Copy',
                          style: GoogleFonts.sora(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: valueStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.sora(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4));
}
