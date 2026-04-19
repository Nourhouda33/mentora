import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../providers/app_settings_provider.dart';
import '../../widgets/mentora_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  // Tri-state: null = still resolving, true = logged in, false = guest
  bool? _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _scaleAnim = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward();

    // Wait for Firebase to restore the persisted auth session before deciding
    // the login state. currentUser can be null for a brief moment on cold start
    // even when a valid session exists.
    FirebaseAuth.instance.authStateChanges().first.then((user) {
      if (mounted) {
        setState(() => _isLoggedIn = user != null);
        // If already authenticated, go straight to home
        if (user != null) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onCreateProject() {
    final loggedIn = _isLoggedIn ?? false;
    if (loggedIn) {
      Navigator.pushNamed(context, AppRoutes.newProject);
    } else {
      // Not authenticated → go to Signup page
      Navigator.pushNamed(context, AppRoutes.login);
    }
  }

  void _onJoinProject() {
    final loggedIn = _isLoggedIn ?? false;
    if (loggedIn) {
      Navigator.pushNamed(context, AppRoutes.joinProject);
    } else {
      // Not authenticated → go to Signup page (consistent with Create Project)
      Navigator.pushNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mt = context.mt;
    final s = context.watch<AppSettingsProvider>();

    return Scaffold(
      backgroundColor: mt.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 8,
              right: 12,
              child: TextButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.about),
                icon: const Icon(Icons.info_outline_rounded,
                    color: AppColors.primary, size: 18),
                label: Text(s.t('about'),
                    style: GoogleFonts.sora(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ),
            ),
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: ScaleTransition(
                        scale: _scaleAnim,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const MentoraLogo(size: 110, withGlow: true),
                            const SizedBox(height: 28),
                            Text(s.t('app_name'),
                                style: GoogleFonts.sora(
                                    color: mt.textPrimary,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4)),
                            const SizedBox(height: 10),
                            Text(s.t('splash_subtitle'),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.sora(
                                    color: mt.textSecondary,
                                    fontSize: 15,
                                    height: 1.5)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _onCreateProject,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadii.md)),
                            elevation: 0,
                          ),
                          child: Text(s.t('create_project'),
                              style: GoogleFonts.sora(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton(
                          onPressed: _onJoinProject,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: mt.textPrimary,
                            side: BorderSide(
                                color: mt.textPrimary, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadii.md)),
                          ),
                          child: Text(s.t('join_project'),
                              style: GoogleFonts.sora(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.login),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.sora(
                                fontSize: 13,
                                color: mt.textSecondary),
                            children: [
                              TextSpan(text: s.t('already_account')),
                              TextSpan(
                                text: ' ${s.t('sign_in')}',
                                style: GoogleFonts.sora(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
