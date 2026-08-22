import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../widgets/campus_backdrop.dart';
import '../widgets/her_campus_logo.dart';
import 'admin_auth_choice_screen.dart';
import 'login_screen.dart';

/// Dark glass role chooser — pink / purple / blue glow backdrop.
class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic));
    _intro.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  void _openRole(UserRole role) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 380),
        pageBuilder: (_, animation, __) => role == UserRole.admin
            ? const AdminAuthChoiceScreen()
            : const LoginScreen(role: UserRole.student),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.03, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CampusBackdrop(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: 'More',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Settings coming soon'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.more_horiz,
                          color: AppTheme.ink.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                    const Center(child: HerCampusLogo(size: 88)),
                    const SizedBox(height: 22),
                    Text(
                      'Welcome to',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.figtree(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.2,
                        color: AppTheme.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const BrandWordmark(),
                    const Spacer(flex: 3),
                    Text(
                      'Which one are you?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.figtree(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _GlassRoleCard(
                            title: 'ADMIN',
                            icon: Icons.vpn_key_rounded,
                            accent: AppTheme.blueSoft,
                            onTap: () => _openRole(UserRole.admin),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _GlassRoleCard(
                            title: 'STUDENT',
                            icon: Icons.school_rounded,
                            accent: AppTheme.pinkSoft,
                            onTap: () => _openRole(UserRole.student),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(flex: 1),
                    Text(
                      'You can switch roles after signing in',
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
        ),
      ),
    );
  }
}

class _GlassRoleCard extends StatefulWidget {
  const _GlassRoleCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_GlassRoleCard> createState() => _GlassRoleCardState();
}

class _GlassRoleCardState extends State<_GlassRoleCard> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          borderRadius: BorderRadius.circular(28),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Ink(
                height: 196,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.52),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.94),
                    width: 1.4,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.figtree(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassIconOrb(
                      icon: widget.icon,
                      color: widget.accent,
                      size: 78,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
