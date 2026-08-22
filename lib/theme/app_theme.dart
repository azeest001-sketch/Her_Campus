import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Light glass UI — white, pink, purple, and blue.
class AppTheme {
  AppTheme._();

  static const Color night = Color(0xFFFDFBFF);
  static const Color nightSoft = Color(0xFFF7F1FF);

  static const Color pink = Color(0xFFE66A9F);
  static const Color pinkSoft = Color(0xFFF08DB8);
  static const Color purple = Color(0xFF8C68D5);
  static const Color purpleDeep = Color(0xFF7353B8);
  static const Color blue = Color(0xFF4F91DB);
  static const Color blueSoft = Color(0xFF68A5E8);
  static const Color teal = Color(0xFF2FA8A0);
  static const Color tealSoft = Color(0xFF5BC4BB);
  static const Color tealDeep = Color(0xFF1F7F7A);
  static const Color adminInk = Color(0xFF1A3344);
  static const Color adminInkMuted = Color(0xFF5A7384);
  static const Color adminWash = Color(0xFFF3FAFC);

  static const Color ink = Color(0xFF2C2440);
  static const Color inkMuted = Color(0xFF746B87);
  static const Color line = Color(0x55FFFFFF);
  static const Color glass = Color(0x22FFFFFF);
  static const Color glassStrong = Color(0x33FFFFFF);

  // Compat aliases used across screens
  static const Color mist = night;
  static const Color blush = pinkSoft;
  static const Color rose = pink;
  static const Color orchid = purple;
  static const Color lilac = purpleDeep;
  static const Color blushDeep = pink;
  static const Color inkSoft = inkMuted;
  static const Color champagne = pinkSoft;
  static const Color berry = pink;
  static const Color berrySoft = pinkSoft;
  static const Color accent = pink;
  static const Color accentDeep = Color(0xFFE84E9A);
  static const Color adminSurface = Color(0x334B6BFF);
  static const Color adminAccent = blueSoft;
  static const Color studentSurface = Color(0x33FF6BB5);
  static const Color studentAccent = pinkSoft;
  static const Color adminMint = adminSurface;
  static const Color adminMintBorder = adminAccent;
  static const Color adminMintDeep = blue;
  static const Color studentRose = studentSurface;
  static const Color studentRoseBorder = studentAccent;
  static const Color studentRoseDeep = pink;

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: night,
      colorScheme: const ColorScheme.light(
        primary: pink,
        onPrimary: Colors.white,
        secondary: blue,
        surface: Colors.white,
        onSurface: ink,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.figtreeTextTheme(base.textTheme).apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.55),
        labelStyle: GoogleFonts.figtree(color: inkMuted),
        hintStyle: GoogleFonts.figtree(color: inkMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: pinkSoft, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.58),
          foregroundColor: ink,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
          ),
          textStyle: GoogleFonts.figtree(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  static ThemeData get dark => light;
}
