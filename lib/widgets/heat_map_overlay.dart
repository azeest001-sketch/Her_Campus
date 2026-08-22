import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Compact legend for heatwave intensity colors.
class HeatMapLegend extends StatelessWidget {
  const HeatMapLegend({super.key});

  static const _items = <(String, Color)>[
    ('Calm', Color(0xFF22C55E)),
    ('Moderate', Color(0xFFEAB308)),
    ('Busy', Color(0xFFF97316)),
    ('Packed', Color(0xFFEF4444)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          for (var i = 0; i < _items.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _items[i].$2,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _items[i].$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.figtree(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.adminInk,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Soft radial glow used as a decorative heat blob (non-map overlay demos).
class HeatMapOverlay extends StatelessWidget {
  const HeatMapOverlay({
    super.key,
    this.intensity = 0.6,
    this.color = const Color(0xFFEF4444),
  });

  final double intensity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final alpha = (0.18 + intensity.clamp(0, 1) * 0.35);
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
