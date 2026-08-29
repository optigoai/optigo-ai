import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// OptigoAI Design System — Premier Light Theme with Ambient Luminance
/// Ultra-modern, bespoke, high-contrast, editorial typography with Plus Jakarta Sans.
class OptigoTheme {
  OptigoTheme._();

  // ---- Primary Brand Palette ----
  static const Color primary = Color(0xFF2563EB);        // Electric Royal Azure
  static const Color primaryLight = Color(0xFF60A5FA);   // Bright Azure
  static const Color primaryDark = Color(0xFF1D4ED8);    // Deep Cobalt
  static const Color primaryTint = Color(0xFFEFF6FF);    // 50 Azure tint
  static const Color accent = Color(0xFF6366F1);         // Radiant Indigo
  static const Color accentLight = Color(0xFF818CF8);

  // ---- Semantic Status Palette ----
  static const Color success = Color(0xFF10B981);       // Emerald
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);       // Amber
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);         // Coral Red
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0EA5E9);          // Ocean Cyan
  static const Color infoLight = Color(0xFFE0F2FE);

  // ---- Priority Action Colors ----
  static const Color urgent = Color(0xFFEF4444);
  static const Color important = Color(0xFFF59E0B);
  static const Color opportunity = Color(0xFF10B981);

  // ---- Neutral Canvas & Text Palette ----
  static const Color background = Color(0xFFF8FAFC);    // Crisp Slate Snow
  static const Color surface = Color(0xFFFFFFFF);       // Pure White Glass
  static const Color surfaceVariant = Color(0xFFF1F5F9);// Subtle Card Fill
  static const Color surfaceHover = Color(0xFFF8FAFC);
  static const Color textPrimary = Color(0xFF0F172A);   // Midnight 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textTertiary = Color(0xFF94A3B8);  // Slate 400
  static const Color divider = Color(0xFFE2E8F0);       // Slate 200
  static const Color border = Color(0xFFCBD5E1);        // Slate 300

  // ---- Background Gradient ----
  static const LinearGradient screenBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFE8F1FD), // Rich soft blue ambient top
      Color(0xFFEFF5FE), // Soft azure transition
      Color(0xFFF6F9FD), // Gentle radiant tint
      Color(0xFFF8FAFC), // Clean lower canvas
    ],
    stops: [0.0, 0.22, 0.55, 1.0],
  );

  // ---- Hero Bento Dark Gradient ----
  static const LinearGradient darkBentoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0B132B), // Deep Midnight
      Color(0xFF1C2541), // Rich Navy
      Color(0xFF1E293B), // Slate 800
    ],
    stops: [0.0, 0.55, 1.0],
  );

  // ---- Spacing Scale ----
  static const double spacingXS = 4;
  static const double spacingSM = 8;
  static const double spacingMD = 16;
  static const double spacingLG = 24;
  static const double spacingXL = 32;
  static const double spacingXXL = 48;

  // ---- Border Radius Scale ----
  static const double radiusSM = 10;
  static const double radiusMD = 16;
  static const double radiusLG = 22;
  static const double radiusXL = 28;
  static const double radiusFull = 999;

  // ---- Box Shadows ----
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.03),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get heroGlowShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.18),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // ---- Theme Data Generator ----
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,

      colorScheme: const ColorScheme.light(
        primary: primary,
        primaryContainer: primaryTint,
        secondary: accent,
        surface: surface,
        error: error,
        onPrimary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -0.4,
        ),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
          side: const BorderSide(color: divider, width: 1.0),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: Color(0xFFDBEAFE), width: 1.2),
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: divider, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: error, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: textTertiary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 0,
      ),

      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: textPrimary,
          letterSpacing: -1.0,
          height: 1.15,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: textPrimary,
          letterSpacing: -0.8,
          height: 1.2,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -0.5,
          height: 1.25,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -0.4,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.2,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleSmall: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textSecondary,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          height: 1.45,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 13.5,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.45,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textTertiary,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
        labelMedium: GoogleFonts.plusJakartaSans(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        labelSmall: GoogleFonts.plusJakartaSans(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
