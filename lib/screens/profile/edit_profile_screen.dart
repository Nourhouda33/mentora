import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    final u = FirebaseAuth.instance.currentUser;
    _nameCtrl = TextEditingController(
      text: u?.displayName ?? u?.email?.split('@').first ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() { _error = 'Name cannot be empty'; _success = null; });
      return;
    }
    setState(() { _loading = true; _error = null; _success = null; });
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.updateDisplayName(name);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'name': name});
      if (mounted) {
        setState(() { _success = 'Profile updated successfully'; _loading = false; });
      }
    } catch (_) {
      if (mounted) {
        setState(() { _error = 'Failed to update. Try again.'; _loading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = TColors.bg(context);
    final surf = TColors.surface(context);
    final txtPrimary = TColors.textPrimary(context);
    final txtSecondary = TColors.textSecondary(context);
    final user = FirebaseAuth.instance.currentUser;
    final initials = (user?.displayName ?? user?.email ?? 'U')[0].toUpperCase();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: txtPrimary),
        title: Text('Edit Profile',
            style: GoogleFonts.sora(
                color: AppColors.primary,
                fontSize: 17,
                fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar preview ─────────────────────────────────────
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  border: Border.all(color: surf, width: 3),
                ),
                child: Center(
                  child: Text(initials,
                      style: GoogleFonts.sora(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(user?.email ?? '',
                  style: GoogleFonts.sora(
                      color: txtSecondary, fontSize: 13)),
            ),
            const SizedBox(height: 32),

            // ── Full Name ──────────────────────────────────────────
            _Label('FULL NAME', txtSecondary),
            const SizedBox(height: 8),
            _Field(
              controller: _nameCtrl,
              hint: 'Enter your full name',
              icon: Icons.person_outline,
              surf: surf,
              txtPrimary: txtPrimary,
              txtSecondary: txtSecondary,
            ),
            const SizedBox(height: 16),

            // ── Email (read-only) ──────────────────────────────────
            _Label('EMAIL', txtSecondary),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: surf,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(
                    color: txtSecondary.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.email_outlined, color: txtSecondary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(user?.email ?? '',
                        style: GoogleFonts.sora(
                            color: txtSecondary, fontSize: 14)),
                  ),
                  Icon(Icons.lock_outline, color: txtSecondary, size: 16),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text('Email cannot be changed',
                  style: GoogleFonts.sora(
                      color: txtSecondary, fontSize: 11)),
            ),

            // ── Error / Success ────────────────────────────────────
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(
                      color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Text(_error!,
                        style: GoogleFonts.sora(
                            color: AppColors.error, fontSize: 12)),
                  ],
                ),
              ),
            ],
            if (_success != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(
                      color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: AppColors.success, size: 16),
                    const SizedBox(width: 8),
                    Text(_success!,
                        style: GoogleFonts.sora(
                            color: AppColors.success, fontSize: 12)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // ── Save button ────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text('Save Changes',
                        style: GoogleFonts.sora(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final Color color;
  const _Label(this.text, this.color);

  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.sora(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2));
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color surf;
  final Color txtPrimary;
  final Color txtSecondary;
  const _Field({required this.controller, required this.hint,
      required this.icon, required this.surf,
      required this.txtPrimary, required this.txtSecondary});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: surf,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(color: txtSecondary.withOpacity(0.15)),
        ),
        child: TextField(
          controller: controller,
          style: GoogleFonts.sora(color: txtPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.sora(color: txtSecondary, fontSize: 14),
            prefixIcon: Icon(icon, color: txtSecondary, size: 20),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      );
}
