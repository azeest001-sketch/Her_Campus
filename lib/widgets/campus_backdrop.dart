import 'dart:ui';

import 'package:flutter/material.dart';

/// Soft watercolor ribbon palette for [CampusBackdrop].
enum CampusBackdropTone {
  /// Default pink / purple / blue campus look.
  campus,

  /// Admin blue / teal look.
  admin,
}

/// Airy white backdrop with asymmetric watercolor-light ribbons.
class CampusBackdrop extends StatelessWidget {
  const CampusBackdrop({
    super.key,
    required this.child,
    this.roleTint,
    this.tone = CampusBackdropTone.campus,
  });

  final Widget child;
  final Color? roleTint;
  final CampusBackdropTone tone;

  @override
  Widget build(BuildContext context) {
    final isAdmin = tone == CampusBackdropTone.admin;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: isAdmin ? const Color(0xFFF3FAFC) : const Color(0xFFFDFBFF),
        ),
        CustomPaint(painter: _RibbonPainter(tone: tone)),
        if (roleTint != null)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.7, -0.85),
                radius: 1.15,
                colors: [
                  roleTint!.withValues(alpha: 0.14),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        // A very light paper veil keeps content crisp while colors show.
        ColoredBox(color: Colors.white.withValues(alpha: 0.10)),
        child,
      ],
    );
  }
}

class _RibbonPainter extends CustomPainter {
  const _RibbonPainter({required this.tone});

  final CampusBackdropTone tone;

  @override
  void paint(Canvas canvas, Size size) {
    void ribbon({
      required Path path,
      required Color color,
      required double width,
      required double blur,
    }) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
      );
    }

    if (tone == CampusBackdropTone.admin) {
      // Soft blue sweep from the upper-left.
      ribbon(
        path: Path()
          ..moveTo(-size.width * .25, size.height * .02)
          ..cubicTo(
            size.width * .18,
            size.height * .03,
            size.width * .06,
            size.height * .35,
            size.width * .45,
            size.height * .43,
          ),
        color: const Color(0xFF7FC0FF).withValues(alpha: .70),
        width: size.width * .22,
        blur: 38,
      );

      // Teal ribbon across the mid/lower diagonal.
      ribbon(
        path: Path()
          ..moveTo(size.width * 1.18, -size.height * .05)
          ..cubicTo(
            size.width * .72,
            size.height * .13,
            size.width * .92,
            size.height * .43,
            size.width * .42,
            size.height * .60,
          )
          ..cubicTo(
            size.width * .18,
            size.height * .69,
            size.width * .30,
            size.height * .88,
            -size.width * .12,
            size.height * 1.02,
          ),
        color: const Color(0xFF5BC4BB).withValues(alpha: .66),
        width: size.width * .18,
        blur: 34,
      );

      // Deeper blue accent arc.
      ribbon(
        path: Path()
          ..moveTo(-size.width * .12, size.height * .78)
          ..cubicTo(
            size.width * .28,
            size.height * .64,
            size.width * .48,
            size.height * .86,
            size.width * .72,
            size.height * .63,
          )
          ..cubicTo(
            size.width * .86,
            size.height * .50,
            size.width * .88,
            size.height * .26,
            size.width * 1.12,
            size.height * .20,
          ),
        color: const Color(0xFF4F91DB).withValues(alpha: .58),
        width: size.width * .10,
        blur: 27,
      );

      // Soft teal wash near the bottom-right.
      ribbon(
        path: Path()
          ..moveTo(size.width * .58, size.height * 1.08)
          ..quadraticBezierTo(
            size.width * .74,
            size.height * .78,
            size.width * 1.10,
            size.height * .84,
          ),
        color: const Color(0xFF9AE5DE).withValues(alpha: .55),
        width: size.width * .14,
        blur: 32,
      );
      return;
    }

    // Pink sweep entering from the upper-left and bending toward center.
    ribbon(
      path: Path()
        ..moveTo(-size.width * .25, size.height * .02)
        ..cubicTo(
          size.width * .18,
          size.height * .03,
          size.width * .06,
          size.height * .35,
          size.width * .45,
          size.height * .43,
        ),
      color: const Color(0xFFFFA8CF).withValues(alpha: .72),
      width: size.width * .22,
      blur: 38,
    );

    // Purple ribbon flows diagonally and remains visibly separate.
    ribbon(
      path: Path()
        ..moveTo(size.width * 1.18, -size.height * .05)
        ..cubicTo(
          size.width * .72,
          size.height * .13,
          size.width * .92,
          size.height * .43,
          size.width * .42,
          size.height * .60,
        )
        ..cubicTo(
          size.width * .18,
          size.height * .69,
          size.width * .30,
          size.height * .88,
          -size.width * .12,
          size.height * 1.02,
        ),
      color: const Color(0xFFB08AF7).withValues(alpha: .68),
      width: size.width * .18,
      blur: 34,
    );

    // Blue highlight runs as a narrower luminous accent.
    ribbon(
      path: Path()
        ..moveTo(-size.width * .12, size.height * .78)
        ..cubicTo(
          size.width * .28,
          size.height * .64,
          size.width * .48,
          size.height * .86,
          size.width * .72,
          size.height * .63,
        )
        ..cubicTo(
          size.width * .86,
          size.height * .50,
          size.width * .88,
          size.height * .26,
          size.width * 1.12,
          size.height * .20,
        ),
      color: const Color(0xFF76B8FF).withValues(alpha: .62),
      width: size.width * .10,
      blur: 27,
    );

    // A small pink tail adds the reference's uneven color balance.
    ribbon(
      path: Path()
        ..moveTo(size.width * .58, size.height * 1.08)
        ..quadraticBezierTo(
          size.width * .74,
          size.height * .78,
          size.width * 1.10,
          size.height * .84,
        ),
      color: const Color(0xFFFFB4D7).withValues(alpha: .55),
      width: size.width * .14,
      blur: 32,
    );
  }

  @override
  bool shouldRepaint(covariant _RibbonPainter oldDelegate) =>
      oldDelegate.tone != tone;
}

/// Bright frosted glass panel — thin white edge like the reference.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 28,
    this.blur = 28,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.62),
                Colors.white.withValues(alpha: 0.28),
              ],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.92),
              width: 1.25,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9F7AEA).withValues(alpha: .12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Frosted icon lens — background color remains visible through the blur.
class GlassIconOrb extends StatelessWidget {
  const GlassIconOrb({
    super.key,
    required this.icon,
    required this.color,
    this.size = 76,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white.withValues(alpha: .24),
                Colors.white.withValues(alpha: .54),
              ],
              stops: const [.25, 1],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.96),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: .8),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(icon, size: size * 0.42, color: color),
        ),
      ),
    );
  }
}
