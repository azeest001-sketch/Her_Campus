import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class HerCampusLogo extends StatelessWidget {
  const HerCampusLogo({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: .8),
            blurRadius: 16,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: AppTheme.purple.withValues(alpha: .16),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: EdgeInsets.all(size * .13),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: .30),
                  Colors.white.withValues(alpha: .62),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: .95),
                width: 1.7,
              ),
            ),
            child: CustomPaint(
              painter: const _HerCampusMarkPainter(),
            ),
          ),
        ),
      ),
    );
  }
}

/// A person held by two protective leaves, inspired by the supplied mark.
class _HerCampusMarkPainter extends CustomPainter {
  const _HerCampusMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Open protective arc.
    canvas.drawArc(
      Rect.fromLTWH(w * .10, h * .08, w * .80, h * .80),
      math.pi * 1.08,
      math.pi * .84,
      false,
      Paint()
        ..color = const Color(0xFFBDAAE8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .065
        ..strokeCap = StrokeCap.round,
    );

    // Left protective leaf.
    final leftLeaf = Path()
      ..moveTo(w * .13, h * .49)
      ..cubicTo(w * .06, h * .72, w * .19, h * .90, w * .42, h * .94)
      ..cubicTo(w * .25, h * .76, w * .22, h * .58, w * .27, h * .39)
      ..cubicTo(w * .20, h * .47, w * .17, h * .53, w * .13, h * .49)
      ..close();
    canvas.drawPath(
      leftLeaf,
      Paint()..color = const Color(0xFF91C9E8),
    );

    // Right protective leaf.
    final rightLeaf = Path()
      ..moveTo(w * .87, h * .49)
      ..cubicTo(w * .94, h * .72, w * .81, h * .90, w * .58, h * .94)
      ..cubicTo(w * .75, h * .76, w * .78, h * .58, w * .73, h * .39)
      ..cubicTo(w * .80, h * .47, w * .83, h * .53, w * .87, h * .49)
      ..close();
    canvas.drawPath(
      rightLeaf,
      Paint()..color = const Color(0xFFE9A9C7),
    );

    // Head.
    canvas.drawCircle(
      Offset(w * .50, h * .37),
      w * .065,
      Paint()..color = const Color(0xFFA995D2),
    );

    // Raised arms.
    final arms = Path()
      ..moveTo(w * .50, h * .49)
      ..cubicTo(w * .42, h * .43, w * .34, h * .40, w * .24, h * .40)
      ..moveTo(w * .50, h * .49)
      ..cubicTo(w * .58, h * .43, w * .66, h * .40, w * .76, h * .40);
    canvas.drawPath(
      arms,
      Paint()
        ..color = const Color(0xFFA995D2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .045
        ..strokeCap = StrokeCap.round,
    );

    // Flowing body.
    final body = Path()
      ..moveTo(w * .50, h * .45)
      ..cubicTo(w * .41, h * .55, w * .41, h * .68, w * .50, h * .88)
      ..cubicTo(w * .57, h * .67, w * .60, h * .54, w * .50, h * .45)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE9A9C7),
            Color(0xFFBDAAE8),
            Color(0xFF91C9E8),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'HER CAMPUS',
          textAlign: TextAlign.center,
          style: GoogleFonts.cormorantGaramond(
            fontSize: compact ? 34 : 42,
            fontWeight: FontWeight.w600,
            letterSpacing: 3.2,
            height: 1.05,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: compact ? 36 : 44,
          height: 2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            gradient: const LinearGradient(
              colors: [AppTheme.pink, AppTheme.purple, AppTheme.blue],
            ),
          ),
        ),
      ],
    );
  }
}
