import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../widgets/campus_backdrop.dart';
import '../widgets/her_campus_logo.dart';
import 'escort_screen.dart';
import 'map_screen.dart';
import 'report_screen.dart';

/// Student home with quick actions (mockup).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.studentEmail = 'student@campus.edu'});

  final String studentEmail;

  @override
  Widget build(BuildContext context) {
    final actions = <_HomeAction>[
      _HomeAction(
        title: 'Campus map',
        subtitle: 'Places & campus area',
        icon: Icons.map,
        color: AppTheme.blue,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const MapScreen()),
        ),
      ),
      _HomeAction(
        title: 'Request peer escort',
        subtitle: 'Don’t walk alone',
        icon: Icons.groups,
        color: AppTheme.purple,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => EscortScreen(studentEmail: studentEmail),
          ),
        ),
      ),
      _HomeAction(
        title: 'Report an event',
        subtitle: 'Tell campus admin',
        icon: Icons.report_gmailerrorred_outlined,
        color: AppTheme.accentDeep,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ReportScreen(studentEmail: studentEmail),
          ),
        ),
      ),
    ];

    return Scaffold(
      body: CampusBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Row(
                children: [
                  const HerCampusLogo(size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Student home',
                          style: GoogleFonts.figtree(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ink,
                          ),
                        ),
                        Text(
                          studentEmail,
                          style: GoogleFonts.figtree(
                            fontSize: 12,
                            color: AppTheme.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Stay safer on campus',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              ...actions.map(
                (action) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: action.onTap,
                      child: GlassPanel(
                        borderRadius: 20,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  action.color.withValues(alpha: 0.15),
                              child: Icon(action.icon, color: action.color),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    action.title,
                                    style: GoogleFonts.figtree(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    action.subtitle,
                                    style: GoogleFonts.figtree(
                                      fontSize: 12,
                                      color: AppTheme.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeAction {
  const _HomeAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}
