import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/app_settings_provider.dart';
import '../../widgets/mentora_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettingsProvider>();

    return Scaffold(
      backgroundColor: context.mt.background,
      appBar: AppBar(
        title: Text(
          s.t('about_title'),
          style: GoogleFonts.sora(
            color: context.mt.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: context.mt.background,
        elevation: 0,
        iconTheme: IconThemeData(color: context.mt.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Logo ──────────────────────────────────────────────
            const Center(child: MentoraLogo(size: 88, withGlow: true)),
            const SizedBox(height: 18),

            // ── App name ──────────────────────────────────────────
            Center(
              child: Text(
                s.t('app_name'),
                style: GoogleFonts.sora(
                  color: context.mt.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Version 1.0.0',
                style: GoogleFonts.sora(
                  color: context.mt.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Description card ──────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.sora(
                    color: context.mt.textSecondary,
                    fontSize: 13.5,
                    height: 1.65,
                  ),
                  children: [
                    const TextSpan(
                      text:
                          'Mentora is an enterprise-grade productivity suite designed to '
                          'streamline document workflows and intelligence gathering. Leveraging '
                          'high-performance ',
                    ),
                    TextSpan(
                      text: 'Firebase ML Kit AI services',
                      style: GoogleFonts.sora(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    const TextSpan(
                      text:
                          ', the application processes complex visual data in real-time, '
                          'ensuring seamless data extraction and contextual understanding directly on-device.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── AI Services section label ─────────────────────────
            Text(
              'AI SERVICES USED',
              style: GoogleFonts.sora(
                color: context.mt.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 14),

            // ── Service cards ─────────────────────────────────────
            _ServiceCard(
              icon: Icons.text_fields_rounded,
              iconLabel: 'Tt',
              useTextIcon: true,
              title: 'Text Recognition (OCR)',
              subtitle:
                  'Instantly convert printed or handwritten text into digital data.',
            ),
            const SizedBox(height: 10),
            _ServiceCard(
              icon: Icons.qr_code_scanner_rounded,
              title: 'Barcode Scanning',
              subtitle:
                  'High-speed detection and decoding of multiple barcode formats.',
            ),
            const SizedBox(height: 10),
            _ServiceCard(
              icon: Icons.storage_rounded,
              title: 'Entity Extraction',
              subtitle:
                  'Extract addresses, dates, and phone numbers from raw text segments.',
            ),
            const SizedBox(height: 10),
            _ServiceCard(
              icon: Icons.face_retouching_natural_rounded,
              title: 'Face Detection',
              subtitle:
                  'Identify facial features and count occupants in visual frames.',
            ),
            const SizedBox(height: 40),

            // ── Footer ────────────────────────────────────────────
            Center(
              child: Text(
                'DEVELOPED BY BINÔME NAMES — IIT 2026',
                style: GoogleFonts.sora(
                  color: AppColors.textSecondary.withOpacity(0.55),
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Service Card ─────────────────────────────────────────────────────────────
class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String? iconLabel;
  final bool useTextIcon;
  final String title;
  final String subtitle;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconLabel,
    this.useTextIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon box
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Center(
              child: useTextIcon && iconLabel != null
                  ? Text(
                      iconLabel!,
                      style: GoogleFonts.sora(
                        color: context.mt.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : Icon(icon, color: context.mt.textPrimary, size: 22),
            ),
          ),
          const SizedBox(width: 14),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.sora(
                    color: context.mt.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.sora(
                    color: context.mt.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
