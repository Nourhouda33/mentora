import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Theme Extension — carries semantic colors for both modes ──────────────────
@immutable
class MentoraTheme extends ThemeExtension<MentoraTheme> {
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final Color inputFill;

  const MentoraTheme({
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.inputFill,
  });

  static const dark = MentoraTheme(
    background: Color(0xFF0D1117),
    surface: Color(0xFF1A2035),
    textPrimary: Colors.white,
    textSecondary: Color(0xFF8B9AB2),
    divider: Color(0xFF252D40),
    inputFill: Color(0xFF1A2035),
  );

  static const light = MentoraTheme(
    background: Color(0xFFF3F4F6),
    surface: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF6B7280),
    divider: Color(0xFFE5E7EB),
    inputFill: Color(0xFFFFFFFF),
  );

  @override
  MentoraTheme copyWith({
    Color? background, Color? surface, Color? textPrimary,
    Color? textSecondary, Color? divider, Color? inputFill,
  }) => MentoraTheme(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    divider: divider ?? this.divider,
    inputFill: inputFill ?? this.inputFill,
  );

  @override
  MentoraTheme lerp(MentoraTheme? other, double t) {
    if (other == null) return this;
    return MentoraTheme(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
    );
  }
}

// ── Convenience accessor ──────────────────────────────────────────────────────
extension MentoraThemeX on BuildContext {
  MentoraTheme get mt =>
      Theme.of(this).extension<MentoraTheme>() ?? MentoraTheme.dark;
}

// ── Static accent/status colors (same in both modes) ─────────────────────────
class AppColors {
  static const primary = Color(0xFF6C9EFF);
  static const accent = Color(0xFF7B6FFF);
  static const success = Color(0xFF3DDC84);
  static const inProgressOrange = Color(0xFFFFB020);
  static const error = Color(0xFFFF4D4D);

  // Legacy dark-mode constants kept for widgets not yet migrated
  static const background = Color(0xFF0D1117);
  static const surface = Color(0xFF1A2035);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF8B9AB2);
}

// ── TColors — theme-aware helpers (kept for backward compat) ──────────────────
class TColors {
  static Color bg(BuildContext ctx) => ctx.mt.background;
  static Color surface(BuildContext ctx) => ctx.mt.surface;
  static Color textPrimary(BuildContext ctx) => ctx.mt.textPrimary;
  static Color textSecondary(BuildContext ctx) => ctx.mt.textSecondary;
  static Color divider(BuildContext ctx) => ctx.mt.divider;
}

class AppRadii {
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
}

// ── Themes ────────────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData dark() => _build(Brightness.dark, MentoraTheme.dark);
  static ThemeData light() => _build(Brightness.light, MentoraTheme.light);

  static ThemeData _build(Brightness brightness, MentoraTheme mt) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      brightness: brightness,
      extensions: [mt],
      scaffoldBackgroundColor: mt.background,
      colorScheme: ColorScheme(
        brightness: brightness,
        background: mt.background,
        surface: mt.surface,
        onSurface: mt.textPrimary,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        onBackground: mt.textPrimary,
      ),
      textTheme: GoogleFonts.soraTextTheme(
          isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme)
          .apply(bodyColor: mt.textPrimary, displayColor: mt.textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: mt.background,
        elevation: 0,
        titleTextStyle: GoogleFonts.sora(
          color: mt.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: mt.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: mt.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: isDark
              ? BorderSide.none
              : BorderSide(color: mt.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: isDark
              ? BorderSide.none
              : BorderSide(color: mt.divider),
        ),
        hintStyle: GoogleFonts.sora(color: mt.textSecondary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.primary
                : mt.textSecondary),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.primary.withOpacity(0.35)
                : mt.textSecondary.withOpacity(0.2)),
      ),
      dividerColor: mt.divider,
      cardColor: mt.surface,
      dialogBackgroundColor: mt.surface,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: mt.surface,
      ),
    );
  }
}
