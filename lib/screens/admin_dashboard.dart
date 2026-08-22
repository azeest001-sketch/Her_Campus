import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/college_service.dart';
import '../theme/app_theme.dart';
import '../widgets/campus_backdrop.dart';
import '../widgets/her_campus_logo.dart';
import 'customisable_map_screen.dart';
import 'floor_calibration_screen.dart';
import 'heatwave_map_screen.dart';
import 'peer_escort_volunteers_screen.dart';
import 'report_inbox_screen.dart';
import 'user_onboarding_screen.dart';

/// Admin home with six feature tiles. Feature screens are mockups for now.
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final college = CollegeService.instance.selectedCollege;
    final campusLabel = college?.name.split(',').first ?? 'Campus admin';

    const blues = <Color>[
      Color(0xFF60A5FA),
      Color(0xFF3B82F6),
      Color(0xFF2563EB),
      Color(0xFF1D4ED8),
      Color(0xFF1E40AF),
      Color(0xFF1E3A8A),
    ];

    final features = <_AdminFeature>[
      _AdminFeature(
        title: 'Customisable Map',
        subtitle: 'Border and places',
        icon: Icons.map,
        color: blues[0],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const CustomisableMapScreen(),
          ),
        ),
      ),
      _AdminFeature(
        title: 'Peer Escort Volunteers',
        subtitle: 'First receivers',
        icon: Icons.groups,
        color: blues[1],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const PeerEscortVolunteersScreen(),
          ),
        ),
      ),
      _AdminFeature(
        title: 'Report Inbox',
        subtitle: 'Student reports',
        icon: Icons.inbox,
        color: blues[2],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ReportInboxScreen()),
        ),
      ),
      _AdminFeature(
        title: 'Floor Calibration',
        subtitle: 'Indoor floors',
        icon: Icons.layers,
        color: blues[3],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const FloorCalibrationScreen(),
          ),
        ),
      ),
      _AdminFeature(
        title: 'Heatwave Map',
        subtitle: 'Crowd heat map',
        icon: Icons.whatshot,
        color: blues[4],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const HeatwaveMapScreen(),
          ),
        ),
      ),
      _AdminFeature(
        title: 'User Onboarding',
        subtitle: 'Invite students',
        icon: Icons.person_add_alt_1,
        color: blues[5],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const UserOnboardingScreen(),
          ),
        ),
      ),
    ];

    return Scaffold(
      body: CampusBackdrop(
        tone: CampusBackdropTone.admin,
        roleTint: AppTheme.tealSoft,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const HerCampusLogo(size: 36),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin dashboard',
                            style: GoogleFonts.figtree(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.adminInk,
                            ),
                          ),
                          Text(
                            campusLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.figtree(
                              fontSize: 12,
                              color: AppTheme.adminInkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Campus tools',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.adminInk,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const cols = 2;
                      const rows = 3;
                      const gap = 8.0;
                      final tileHeight =
                          (constraints.maxHeight - gap * (rows - 1)) / rows;

                      return GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: features.length,
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          mainAxisSpacing: gap,
                          crossAxisSpacing: gap,
                          mainAxisExtent: tileHeight,
                        ),
                        itemBuilder: (context, index) {
                          return _FeatureTile(feature: features[index]);
                        },
                      );
                    },
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

class _AdminFeature {
  const _AdminFeature({
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

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.feature});

  final _AdminFeature feature;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: feature.onTap,
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withValues(alpha: 0.55),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.85),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.blue.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),
                  Icon(feature.icon, size: 40, color: feature.color),
                  const Spacer(),
                  Text(
                    feature.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.figtree(
                      fontSize: 12.5,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.adminInk,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    feature.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.figtree(
                      fontSize: 10.5,
                      color: AppTheme.adminInkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
