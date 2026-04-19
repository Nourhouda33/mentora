import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/collaboration_provider.dart';

class JoinProjectScreen extends StatefulWidget {
  const JoinProjectScreen({super.key});

  @override
  State<JoinProjectScreen> createState() => _JoinProjectScreenState();
}

class _JoinProjectScreenState extends State<JoinProjectScreen> {
  final _codeCtrl = TextEditingController();
  final MobileScannerController _scannerCtrl = MobileScannerController();

  bool _scanned = false; // évite les scans multiples
  bool _loading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _scannerCtrl.dispose();
    super.dispose();
  }

  // ── Traitement commun code/lien ────────────────────────────────────────────
  void _handleCode(String raw) {
    if (_scanned || raw.trim().isEmpty) return;
    setState(() => _scanned = true);
    _scannerCtrl.stop();
    _codeCtrl.text = raw.trim();
    _join(raw.trim());
  }

  Future<void> _join([String? override]) async {
    final input = override ?? _codeCtrl.text.trim();
    if (input.isEmpty) return;

    setState(() => _loading = true);

    final project =
        await context.read<CollaborationProvider>().joinProjectByCode(input);

    if (!mounted) return;
    setState(() => _loading = false);

    if (project != null) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.projectDetail,
        arguments: project,
      );
    } else {
      setState(() => _scanned = false);
      _scannerCtrl.start();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Code invalide. Réessayez.',
            style: GoogleFonts.sora(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettingsProvider>();

    return Scaffold(
      backgroundColor: context.mt.background,
      appBar: AppBar(
        title: Text(
          s.t('join_project'),
          style: GoogleFonts.sora(
            color: context.mt.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: context.mt.background,
        iconTheme: IconThemeData(color: context.mt.textPrimary),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ── QR Scanner ─────────────────────────────────────────────────
            _QrScannerBox(
              controller: _scannerCtrl,
              onDetect: (capture) {
                final barcode = capture.barcodes.firstOrNull;
                if (barcode?.rawValue != null) {
                  _handleCode(barcode!.rawValue!);
                }
              },
            ),
            const SizedBox(height: 28),

            // ── OR ENTER CODE MANUALLY ─────────────────────────────────────
            Text(
              'OR ENTER CODE MANUALLY',
              style: GoogleFonts.sora(
                color: context.mt.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 14),

            // ── Code input ─────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: TextField(
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(
                  color: context.mt.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 6,
                ),
                decoration: InputDecoration(
                  hintText: 'ENTER INVITATION CODE',
                  hintStyle: GoogleFonts.sora(
                    color: context.mt.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                  counterText: '',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 18),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Join button ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : () => _join(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        s.t('join'),
                        style: GoogleFonts.sora(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Powered by footer ──────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.hub_rounded,
                      color: AppColors.primary, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'POWERED BY ML KIT BARCODE SCANNING',
                    style: GoogleFonts.sora(
                      color: context.mt.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── QR Scanner Box avec overlay coins bleus ───────────────────────────────────
class _QrScannerBox extends StatelessWidget {
  final MobileScannerController controller;
  final void Function(BarcodeCapture) onDetect;

  const _QrScannerBox({
    required this.controller,
    required this.onDetect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Stack(
          children: [
            // Camera feed
            MobileScanner(
              controller: controller,
              onDetect: onDetect,
            ),

            // Scan line animation
            _ScanLine(),

            // Corner overlays
            Positioned.fill(
              child: CustomPaint(painter: _CornerPainter()),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated scan line ────────────────────────────────────────────────────────
class _ScanLine extends StatefulWidget {
  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Positioned(
        top: _anim.value * 240,
        left: 20,
        right: 20,
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppColors.primary.withOpacity(0.9),
                Colors.transparent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.6),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Corner painter (coins bleus) ──────────────────────────────────────────────
class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 24.0;
    const pad = 16.0;

    // Top-left
    canvas.drawLine(
        Offset(pad, pad + len), Offset(pad, pad), paint);
    canvas.drawLine(
        Offset(pad, pad), Offset(pad + len, pad), paint);

    // Top-right
    canvas.drawLine(
        Offset(size.width - pad - len, pad),
        Offset(size.width - pad, pad), paint);
    canvas.drawLine(
        Offset(size.width - pad, pad),
        Offset(size.width - pad, pad + len), paint);

    // Bottom-left
    canvas.drawLine(
        Offset(pad, size.height - pad - len),
        Offset(pad, size.height - pad), paint);
    canvas.drawLine(
        Offset(pad, size.height - pad),
        Offset(pad + len, size.height - pad), paint);

    // Bottom-right
    canvas.drawLine(
        Offset(size.width - pad - len, size.height - pad),
        Offset(size.width - pad, size.height - pad), paint);
    canvas.drawLine(
        Offset(size.width - pad, size.height - pad - len),
        Offset(size.width - pad, size.height - pad), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
