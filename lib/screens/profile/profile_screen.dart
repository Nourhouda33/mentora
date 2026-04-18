import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../providers/app_settings_provider.dart';
import '../../widgets/mentora_logo.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Real Firebase user
  static String get _realName {
    final u = FirebaseAuth.instance.currentUser;
    return u?.displayName ?? u?.email?.split('@').first ?? 'User';
  }
  static String get _realEmail =>
      FirebaseAuth.instance.currentUser?.email ?? '';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      // ── AppBar ──────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Mentora logo small in appbar
            const MentoraLogo(size: 32, withGlow: false),
            const SizedBox(width: 10),
            Text(
              s.t('app_name'),
              style: GoogleFonts.sora(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Avatar + name + email ──────────────────────────
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary,
                                border: Border.all(
                                    color: AppColors.surface, width: 3),
                              ),
                              child: Center(
                                child: Text(
                                  _realName.isNotEmpty ? _realName[0].toUpperCase() : "U",
                                  style: GoogleFonts.sora(
                                    color: Colors.white,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            // Edit badge
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.background, width: 2),
                                ),
                                child: const Icon(Icons.edit_rounded,
                                    color: Colors.white, size: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _realName,
                          style: GoogleFonts.sora(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _realEmail,
                          style: GoogleFonts.sora(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Action buttons ─────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          label: '+ New Project',
                          isPrimary: true,
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.newProject),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionBtn(
                          label: '⊞  Scan QR',
                          isPrimary: false,
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.joinProject),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── PREFERENCES ───────────────────────────────────
                  _SectionLabel('PREFERENCES'),
                  const SizedBox(height: 10),
                  _PrefsCard(s: s),
                  const SizedBox(height: 20),

                  // ── ACCOUNT ───────────────────────────────────────
                  _SectionLabel('ACCOUNT'),
                  const SizedBox(height: 10),
                  _MenuCard(
                    items: [
                      _MenuItem(
                        icon: Icons.manage_accounts_outlined,
                        iconColor: AppColors.inProgressOrange,
                        label: 'Edit Profile',
                        onTap: () => _showEditProfileDialog(context, s),
                      ),
                      _MenuItem(
                        icon: Icons.lock_reset_rounded,
                        iconColor: AppColors.inProgressOrange,
                        label: 'Change Password',
                        onTap: () => _showChangePasswordDialog(context, s),
                      ),
                      _MenuItem(
                        icon: Icons.smart_toy_outlined,
                        iconColor: AppColors.accent,
                        label: 'ML History',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.mlHistory),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── ABOUT ─────────────────────────────────────────
                  _SectionLabel('ABOUT'),
                  const SizedBox(height: 10),
                  _MenuCard(
                    items: [
                      _MenuItem(
                        icon: Icons.info_outline_rounded,
                        iconColor: AppColors.textSecondary,
                        label: 'About Mentora',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.about),
                      ),
                      _MenuItem(
                        icon: Icons.tag_rounded,
                        iconColor: AppColors.textSecondary,
                        label: 'Version',
                        trailing: Text(
                          '1.0.0',
                          style: GoogleFonts.sora(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        showArrow: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Sign Out ──────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => _signOut(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error.withOpacity(0.18),
                        foregroundColor: AppColors.error,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          side: BorderSide(
                              color: AppColors.error.withOpacity(0.3)),
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded,
                          color: AppColors.error, size: 20),
                      label: Text(
                        'Sign Out',
                        style: GoogleFonts.sora(
                          color: AppColors.error,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom nav bar ─────────────────────────────────────────
          _BottomBar(
            onHomeTap: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.home),
          ),
        ],
      ),
    );
  }

  // ── Sign out ───────────────────────────────────────────────────────────────
  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.splash,
        (route) => false,
      );
    }
  }

  // ── Edit profile dialog ────────────────────────────────────────────────────
  void _showEditProfileDialog(BuildContext context, AppSettingsProvider s) {
    final nameCtrl = TextEditingController(text: _realName);
    final emailCtrl = TextEditingController(text: _realEmail);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md)),
        title: Text('Edit Profile',
            style: GoogleFonts.sora(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DlgField(ctrl: nameCtrl, hint: 'Full name'),
            const SizedBox(height: 12),
            _DlgField(ctrl: emailCtrl, hint: 'Email'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.t('cancel'),
                style: GoogleFonts.sora(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.sm)),
            ),
            child: Text(s.t('save'),
                style: GoogleFonts.sora(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Change password dialog ─────────────────────────────────────────────────
  void _showChangePasswordDialog(
      BuildContext context, AppSettingsProvider s) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md)),
        title: Text('Change Password',
            style: GoogleFonts.sora(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DlgField(ctrl: currentCtrl, hint: 'Current password', obscure: true),
            const SizedBox(height: 12),
            _DlgField(ctrl: newCtrl, hint: 'New password', obscure: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.t('cancel'),
                style: GoogleFonts.sora(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.sm)),
            ),
            child: Text(s.t('save'),
                style: GoogleFonts.sora(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Preferences card ──────────────────────────────────────────────────────────
class _PrefsCard extends StatelessWidget {
  final AppSettingsProvider s;
  const _PrefsCard({required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        children: [
          // Dark Mode
          _SwitchRow(
            icon: Icons.dark_mode_outlined,
            iconColor: AppColors.primary,
            label: s.t('dark_mode'),
            value: s.darkMode,
            onChanged: (v) => context.read<AppSettingsProvider>().setDarkMode(v),
          ),
          _Divider(),

          // Language chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.language_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Text(
                  s.t('language'),
                  style: GoogleFonts.sora(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                _LangChip(
                  label: 'FRA',
                  selected: s.languageCode == 'fr',
                  onTap: () =>
                      context.read<AppSettingsProvider>().setLanguage('fr'),
                ),
                const SizedBox(width: 6),
                _LangChip(
                  label: 'ENG',
                  selected: s.languageCode == 'en',
                  onTap: () =>
                      context.read<AppSettingsProvider>().setLanguage('en'),
                ),
                const SizedBox(width: 6),
                _LangChip(
                  label: 'ARA',
                  selected: s.languageCode == 'ar',
                  onTap: () =>
                      context.read<AppSettingsProvider>().setLanguage('ar'),
                ),
              ],
            ),
          ),
          _Divider(),

          // Notifications
          _SwitchRow(
            icon: Icons.notifications_outlined,
            iconColor: AppColors.primary,
            label: s.t('notifications'),
            value: s.notificationsEnabled,
            onChanged: (v) =>
                context.read<AppSettingsProvider>().setNotifications(v),
          ),
          _Divider(),

          // Vibration
          _SwitchRow(
            icon: Icons.vibration_rounded,
            iconColor: AppColors.primary,
            label: s.t('vibration'),
            value: s.vibrationEnabled,
            onChanged: (v) =>
                context.read<AppSettingsProvider>().setVibration(v),
          ),
          _Divider(),

          // Sound
          _SwitchRow(
            icon: Icons.volume_up_outlined,
            iconColor: AppColors.primary,
            label: s.t('sound'),
            value: s.soundEnabled,
            onChanged: (v) =>
                context.read<AppSettingsProvider>().setSound(v),
          ),
        ],
      ),
    );
  }
}

// ── Menu card ─────────────────────────────────────────────────────────────────
class _MenuCard extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _MenuRowWidget(item: items[i]),
            if (i < items.length - 1) _Divider(),
          ],
        ],
      ),
    );
  }
}

class _MenuRowWidget extends StatelessWidget {
  final _MenuItem item;
  const _MenuRowWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: item.iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, color: item.iconColor, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: GoogleFonts.sora(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (item.trailing != null) item.trailing!,
            if (item.showArrow)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Switch row ────────────────────────────────────────────────────────────────
class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.sora(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withOpacity(0.35),
            inactiveThumbColor: AppColors.textSecondary,
            inactiveTrackColor: AppColors.textSecondary.withOpacity(0.2),
          ),
        ],
      ),
    );
  }
}

// ── Language chip ─────────────────────────────────────────────────────────────
class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.2)
              : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.textSecondary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.sora(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primary.withOpacity(0.18)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: isPrimary
              ? Border.all(color: AppColors.primary.withOpacity(0.4))
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.sora(
              color: isPrimary ? AppColors.primary : AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bottom nav bar ────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final VoidCallback onHomeTap;
  const _BottomBar({required this.onHomeTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Color(0xFF252D40), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: onHomeTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.home_rounded,
                    color: AppColors.textSecondary, size: 22),
                const SizedBox(height: 3),
                Text(
                  'Home',
                  style: GoogleFonts.sora(
                    color: AppColors.textSecondary,
                    fontSize: 10,
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

// ── Helpers ───────────────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: AppColors.background,
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.sora(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      );
}

class _DlgField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final bool obscure;
  const _DlgField(
      {required this.ctrl, required this.hint, this.obscure = false});

  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        obscureText: obscure,
        style: GoogleFonts.sora(color: AppColors.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.sora(color: AppColors.textSecondary, fontSize: 13),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      );
}

// ── Data ──────────────────────────────────────────────────────────────────────
class _MenuItem {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showArrow;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.onTap,
    this.trailing,
    this.showArrow = true,
  });
}
