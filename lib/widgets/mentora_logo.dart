import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Logo Mentora : livre ouvert + personnages + flèche + étoile
class MentoraLogo extends StatelessWidget {
  final double size;
  final bool withGlow;

  const MentoraLogo({
    super.key,
    this.size = 110,
    this.withGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8AABFF), Color(0xFF6C9EFF)],
        ),
        boxShadow: withGlow
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.45),
                  blurRadius: size * 0.44,
                  spreadRadius: size * 0.07,
                ),
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.20),
                  blurRadius: size * 0.73,
                  spreadRadius: size * 0.15,
                ),
              ]
            : null,
      ),
      child: CustomPaint(
        painter: _MentoraLogoPainter(),
      ),
    );
  }
}

class _MentoraLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    final paint = Paint()..style = PaintingStyle.fill;

    // ── Book (open) ────────────────────────────────────────────────
    paint.color = const Color(0xFF0D1117);
    final bookPath = Path()
      ..moveTo(cx - w * 0.28, cy + h * 0.12)
      ..lineTo(cx - w * 0.28, cy - h * 0.18)
      ..quadraticBezierTo(cx - w * 0.15, cy - h * 0.22, cx, cy - h * 0.18)
      ..quadraticBezierTo(cx + w * 0.15, cy - h * 0.22, cx + w * 0.28, cy - h * 0.18)
      ..lineTo(cx + w * 0.28, cy + h * 0.12)
      ..quadraticBezierTo(cx + w * 0.15, cy + h * 0.16, cx, cy + h * 0.12)
      ..quadraticBezierTo(cx - w * 0.15, cy + h * 0.16, cx - w * 0.28, cy + h * 0.12)
      ..close();
    canvas.drawPath(bookPath, paint);

    // Center line
    paint.color = const Color(0xFF6C9EFF);
    paint.strokeWidth = w * 0.015;
    paint.style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx, cy - h * 0.18),
      Offset(cx, cy + h * 0.12),
      paint,
    );
    paint.style = PaintingStyle.fill;

    // ── Person 1 (left, with graduation cap) ──────────────────────
    paint.color = const Color(0xFF6C9EFF);
    // Head
    canvas.drawCircle(Offset(cx - w * 0.15, cy - h * 0.08), w * 0.055, paint);
    // Body
    final body1 = Path()
      ..moveTo(cx - w * 0.15, cy - h * 0.02)
      ..lineTo(cx - w * 0.20, cy + h * 0.08)
      ..lineTo(cx - w * 0.10, cy + h * 0.08)
      ..close();
    canvas.drawPath(body1, paint);

    // Graduation cap
    final capPath = Path()
      ..moveTo(cx - w * 0.22, cy - h * 0.13)
      ..lineTo(cx - w * 0.08, cy - h * 0.13)
      ..lineTo(cx - w * 0.15, cy - h * 0.16)
      ..close();
    canvas.drawPath(capPath, paint);
    // Tassel
    canvas.drawCircle(Offset(cx - w * 0.08, cy - h * 0.13), w * 0.015, paint);

    // ── Person 2 (right, smaller) ──────────────────────────────────
    paint.color = const Color(0xFF8AABFF);
    // Head
    canvas.drawCircle(Offset(cx + w * 0.08, cy - h * 0.04), w * 0.045, paint);
    // Body
    final body2 = Path()
      ..moveTo(cx + w * 0.08, cy + h * 0.01)
      ..lineTo(cx + w * 0.04, cy + h * 0.08)
      ..lineTo(cx + w * 0.12, cy + h * 0.08)
      ..close();
    canvas.drawPath(body2, paint);

    // ── Arrow (growth) ─────────────────────────────────────────────
    paint.color = const Color(0xFF0D1117);
    paint.strokeWidth = w * 0.025;
    paint.style = PaintingStyle.stroke;
    paint.strokeCap = StrokeCap.round;
    final arrowPath = Path()
      ..moveTo(cx + w * 0.12, cy + h * 0.02)
      ..lineTo(cx + w * 0.24, cy - h * 0.10);
    canvas.drawPath(arrowPath, paint);
    // Arrow head
    paint.style = PaintingStyle.fill;
    final arrowHead = Path()
      ..moveTo(cx + w * 0.24, cy - h * 0.10)
      ..lineTo(cx + w * 0.20, cy - h * 0.08)
      ..lineTo(cx + w * 0.22, cy - h * 0.04)
      ..close();
    canvas.drawPath(arrowHead, paint);

    // ── Star (sparkle) ─────────────────────────────────────────────
    paint.color = const Color(0xFF6C9EFF);
    final starSize = w * 0.04;
    final starX = cx + w * 0.20;
    final starY = cy - h * 0.16;
    final starPath = Path()
      ..moveTo(starX, starY - starSize)
      ..lineTo(starX + starSize * 0.3, starY - starSize * 0.3)
      ..lineTo(starX + starSize, starY)
      ..lineTo(starX + starSize * 0.3, starY + starSize * 0.3)
      ..lineTo(starX, starY + starSize)
      ..lineTo(starX - starSize * 0.3, starY + starSize * 0.3)
      ..lineTo(starX - starSize, starY)
      ..lineTo(starX - starSize * 0.3, starY - starSize * 0.3)
      ..close();
    canvas.drawPath(starPath, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
