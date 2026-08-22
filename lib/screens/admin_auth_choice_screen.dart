import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../widgets/campus_backdrop.dart';
import '../widgets/her_campus_logo.dart';
import 'admin_signup_screen.dart';
import 'login_screen.dart';

/// Lets an administrator choose between signing in and creating an account.
class AdminAuthChoiceScreen extends StatelessWidget {
  const AdminAuthChoiceScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CampusBackdrop(
        roleTint: AppTheme.blueSoft,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppTheme.ink,
                  ),
                ),
                const Spacer(flex: 2),
                const Center(child: HerCampusLogo(size: 84)),
                const SizedBox(height: 24),
                Text(
                  'Admin access',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose how you would like to continue',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.figtree(
                    fontSize: 14,
                    color: AppTheme.inkMuted,
                  ),
                ),
                const Spacer(flex: 2),
                _AuthOption(
                  icon: Icons.login_rounded,
                  title: 'Log in',
                  description: 'I already have an admin account',
                  color: AppTheme.blueSoft,
                  onTap: () => _open(
                    context,
                    const LoginScreen(role: UserRole.admin),
                  ),
                ),
                const SizedBox(height: 16),
                _AuthOption(
                  icon: Icons.person_add_alt_1_rounded,
                  title: 'Sign up',
                  description: 'I am a new verified administrator',
                  color: AppTheme.purple,
                  onTap: () => _open(
                    context,
                    const AdminSignUpScreen(),
                  ),
                ),
                const Spacer(flex: 3),
                Text(
                  'New admin accounts require campus verification',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.figtree(
                    fontSize: 12,
                    color: AppTheme.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthOption extends StatelessWidget {
  const _AuthOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: GlassPanel(
          borderRadius: 26,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              GlassIconOrb(icon: icon, color: color, size: 58),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.figtree(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.figtree(
                        fontSize: 13,
                        color: AppTheme.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
