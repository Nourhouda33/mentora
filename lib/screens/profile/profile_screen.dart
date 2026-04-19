import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../providers/app_settings_provider.dart';
import '../../widgets/mentora_logo.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String get _name {
    final u = FirebaseAuth.instance.currentUser;
    return u?.displayName ?? u?.email?.split('@').first ?? 'User';
  }

  String get _email => FirebaseAuth.instance.currentUser?.email ?? '';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettingsProvider>();
    final bg = TColors.bg(context);
    final surf = TColors.surface(context);
    final txtPrimary = TColors.textPrimary(context);
    final txtSecondary = TColors.textSecondary(context);
    final divColor = TColors.divider(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const MentoraLogo(size: 32, withGlow: false),
            const SizedBox(width: 10),
            Text(s.t('app_name'),
                style: GoogleFonts.sora(
                    color: txtPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600)),
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
                  // ── Avatar ─────────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const EditProfileScreen()),
                            );
                            if (mounted) setState(() {});
                          },
                          child: Stack(
                            children: [
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                  border: Border.all(color: surf, width: 3),
                                ),
                                child: Center(
                                  child: Text(
                                    _name.isNotEmpty
                                        ? _name[0].toUpperCase()
                                        : 'U',
                                    style: GoogleFonts.sora(
                                        color: Colors.white,
                                        fontSize: 34,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: bg, width: 2),
                                  ),
                                  child: const Icon(Icons.edit_rounded,
                                      color: Colors.white, size: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(_name,
                            style: GoogleFonts.sora(
                                color: txtPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(_email,
                            style: GoogleFonts.sora(
                                color: txtSecondary, fontSize: 13)),
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
                          surf: surf,
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.newProject),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionBtn(
                          label: '⊞  Scan QR',
                          isPrimary: false,
                          surf: surf,
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.joinProject),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── PREFERENCES ───────────────────────────────────
                  _SectionLabel('PREFERENCES', txtSecondary),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: surf,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Column(
                      children: [
                        // Dark / Light mode toggle
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                s.darkMode
                                    ? Icons.dark_mode_outlined
                                    : Icons.light_mode_outlined,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  s.darkMode ? s.t('dark_mode') : 'Mode clair',
                                  style: GoogleFonts.sora(
                                      color: txtPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              Switch(
                                value: s.darkMode,
                                onChanged: (v) => context
                                    .read<AppSettingsProvider>()
                                    .setDarkMode(v),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: divColor,
                            indent: 16, endIndent: 16),

                        // Language
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              const Icon(Icons.language_rounded,
                                  color: AppColors.primary, size: 20),
                              const SizedBox(width: 12),
                              Text(s.t('language'),
                                  style: GoogleFonts.sora(
                                      color: txtPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(width: 16),
                              _LangChip(
                                label: 'FRA',
                                selected: s.languageCode == 'fr',
                                onTap: () => context
                                    .read<AppSettingsProvider>()
                                    .setLanguage('fr'),
                              ),
                              const SizedBox(width: 6),
                              _LangChip(
                                label: 'ENG',
                                selected: s.languageCode == 'en',
                                onTap: () => context
                                    .read<AppSettingsProvider>()
                                    .setLanguage('en'),
                              ),
                              const SizedBox(width: 6),
                              _LangChip(
                                label: 'ARA',
                                selected: s.languageCode == 'ar',
                                onTap: () => context
                                    .read<AppSettingsProvider>()
                                    .setLanguage('ar'),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: divColor,
                            indent: 16, endIndent: 16),

                        _SwitchTile(
                          icon: Icons.notifications_outlined,
                          label: s.t('notifications'),
                          value: s.notificationsEnabled,
                          txtPrimary: txtPrimary,
                          onChanged: (v) => context
                              .read<AppSettingsProvider>()
                              .setNotifications(v),
                        ),
                        Divider(height: 1, color: divColor,
                            indent: 16, endIndent: 16),
                        _SwitchTile(
                          icon: Icons.vibration_rounded,
                          label: s.t('vibration'),
                          value: s.vibrationEnabled,
                          txtPrimary: txtPrimary,
                          onChanged: (v) => context
                              .read<AppSettingsProvider>()
                              .setVibration(v),
                        ),
                        Divider(height: 1, color: divColor,
                            indent: 16, endIndent: 16),
                        _SwitchTile(
                          icon: Icons.volume_up_outlined,
                          label: s.t('sound'),
                          value: s.soundEnabled,
                          txtPrimary: txtPrimary,
                          onChanged: (v) =>
                              context.read<AppSettingsProvider>().setSound(v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── ACCOUNT ───────────────────────────────────────
                  _SectionLabel('ACCOUNT', txtSecondary),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: surf,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Column(
                      children: [
                        _MenuTile(
                          icon: Icons.manage_accounts_outlined,
                          iconColor: AppColors.inProgressOrange,
                          label: 'Edit Profile',
                          txtPrimary: txtPrimary,
                          txtSecondary: txtSecondary,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const EditProfileScreen()),
                            );
                            if (mounted) setState(() {});
                          },
                        ),
                        Divider(height: 1, color: divColor,
                            indent: 16, endIndent: 16),
                        _MenuTile(
                          icon: Icons.lock_reset_rounded,
                          iconColor: AppColors.inProgressOrange,
                          label: 'Change Password',
                          txtPrimary: txtPrimary,
                          txtSecondary: txtSecondary,
                          onTap: () =>
                              _showChangePasswordDialog(context, s, surf,
                                  txtPrimary, txtSecondary),
                        ),
                        Divider(height: 1, color: divColor,
                            indent: 16, endIndent: 16),
                        _MenuTile(
                          icon: Icons.smart_toy_outlined,
                          iconColor: AppColors.accent,
                          label: 'ML History',
                          txtPrimary: txtPrimary,
                          txtSecondary: txtSecondary,
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.mlHistory),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── ABOUT ─────────────────────────────────────────
                  _SectionLabel('ABOUT', txtSecondary),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: surf,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Column(
                      children: [
                        _MenuTile(
                          icon: Icons.info_outline_rounded,
                          iconColor: txtSecondary,
                          label: 'About Mentora',
                          txtPrimary: txtPrimary,
                          txtSecondary: txtSecondary,
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.about),
                        ),
                        Divider(height: 1, color: divColor,
                            indent: 16, endIndent: 16),
                        _MenuTile(
                          icon: Icons.tag_rounded,
                          iconColor: txtSecondary,
                          label: 'Version',
                          txtPrimary: txtPrimary,
                          txtSecondary: txtSecondary,
                          trailing: Text('1.0.0',
                              style: GoogleFonts.sora(
                                  color: txtSecondary, fontSize: 13)),
                          showArrow: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Sign Out ──────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => _signOut(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error.withOpacity(0.12),
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
                      label: Text('Sign Out',
                          style: GoogleFonts.sora(
                              color: AppColors.error,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _BottomBar(
            surf: surf,
            divColor: divColor,
            txtSecondary: txtSecondary,
            onHomeTap: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.home),
          ),
        ],
      ),
    );
  }

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.splash, (r) => false);
    }
  }

  void _showChangePasswordDialog(BuildContext context, AppSettingsProvider s,
      Color surf, Color txtPrimary, Color txtSecondary) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: surf,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md)),
          title: Text('Change Password',
              style: GoogleFonts.sora(
                  color: txtPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DlgField(ctrl: currentCtrl, hint: 'Current password',
                  obscure: true, surf: surf, txtPrimary: txtPrimary,
                  txtSecondary: txtSecondary),
              const SizedBox(height: 12),
              _DlgField(ctrl: newCtrl, hint: 'New password',
                  obscure: true, surf: surf, txtPrimary: txtPrimary,
                  txtSecondary: txtSecondary),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!,
                    style: GoogleFonts.sora(
                        color: AppColors.error, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.t('cancel'),
                  style: GoogleFonts.sora(color: txtSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final current = currentCtrl.text.trim();
                final newPass = newCtrl.text.trim();
                if (current.isEmpty || newPass.isEmpty) {
                  setDlg(() => error = 'Fill all fields');
                  return;
                }
                if (newPass.length < 6) {
                  setDlg(() => error = 'Min 6 characters');
                  return;
                }
                try {
                  final user = FirebaseAuth.instance.currentUser!;
                  final cred = EmailAuthProvider.credential(
                      email: user.email!, password: current);
                  await user.reauthenticateWithCredential(cred);
                  await user.updatePassword(newPass);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Password updated',
                          style: GoogleFonts.sora(color: Colors.white)),
                      backgroundColor: AppColors.success,
                    ));
                  }
                } on FirebaseAuthException catch (e) {
                  setDlg(() => error = e.code == 'wrong-password'
                      ? 'Current password incorrect'
                      : 'Failed to update');
                }
              },
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
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final Color txtPrimary;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({required this.icon, required this.label,
      required this.value, required this.txtPrimary, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.sora(
                      color: txtPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      );
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color txtPrimary;
  final Color txtSecondary;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showArrow;

  const _MenuTile({
    required this.icon, required this.iconColor, required this.label,
    required this.txtPrimary, required this.txtSecondary,
    this.onTap, this.trailing, this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 17),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: GoogleFonts.sora(
                        color: txtPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ),
              if (trailing != null) trailing!,
              if (showArrow)
                Icon(Icons.chevron_right_rounded,
                    color: txtSecondary, size: 20),
            ],
          ),
        ),
      );
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LangChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : TColors.textSecondary(context).withOpacity(0.3),
            ),
          ),
          child: Text(label,
              style: GoogleFonts.sora(
                  color: selected
                      ? AppColors.primary
                      : TColors.textSecondary(context),
                  fontSize: 11,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w400)),
        ),
      );
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final Color surf;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.isPrimary,
      required this.surf, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: isPrimary ? AppColors.primary.withOpacity(0.18) : surf,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: isPrimary
                ? Border.all(color: AppColors.primary.withOpacity(0.4))
                : null,
          ),
          child: Center(
            child: Text(label,
                style: GoogleFonts.sora(
                    color: isPrimary
                        ? AppColors.primary
                        : TColors.textPrimary(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      );
}

class _BottomBar extends StatelessWidget {
  final Color surf;
  final Color divColor;
  final Color txtSecondary;
  final VoidCallback onHomeTap;
  const _BottomBar({required this.surf, required this.divColor,
      required this.txtSecondary, required this.onHomeTap});

  @override
  Widget build(BuildContext context) => Container(
        height: 64,
        decoration: BoxDecoration(
          color: surf,
          border: Border(top: BorderSide(color: divColor, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GestureDetector(
              onTap: onHomeTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_rounded, color: txtSecondary, size: 22),
                  const SizedBox(height: 3),
                  Text('Home',
                      style: GoogleFonts.sora(
                          color: txtSecondary, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.sora(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4));
}

class _DlgField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final bool obscure;
  final Color surf;
  final Color txtPrimary;
  final Color txtSecondary;
  const _DlgField({required this.ctrl, required this.hint,
      this.obscure = false, required this.surf,
      required this.txtPrimary, required this.txtSecondary});

  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        obscureText: obscure,
        style: GoogleFonts.sora(color: txtPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.sora(color: txtSecondary, fontSize: 13),
          filled: true,
          fillColor: TColors.bg(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      );
}
