import 'package:flutter/material.dart';

class AppTheme {
  // SOS & Emergency Colors
  static const Color sosRed = Color(0xFFDC2626);
  static const Color sosRedDark = Color(0xFF991B1B);
  static const Color sosRedLight = Color(0xFFFEE2E2);

  // Status & Medical Accents
  static const Color medicalBlue = Color(0xFF2563EB);
  static const Color medicalBlueDark = Color(0xFF1E40AF);
  static const Color warningOrange = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color successGreen = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);

  // Neutrals (Slate)
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color cardLight = Colors.white;
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Dark Neutrals
  static const Color bgDark = Color(0xFF090D16);
  static const Color cardDark = Color(0xFF131B2E);
  static const Color textLight = Color(0xFFF8FAFC);
  static const Color textMutedDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF1E293B);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: sosRed,
        brightness: Brightness.light,
        primary: sosRed,
        surface: bgLight,
      ),
      scaffoldBackgroundColor: bgLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textDark,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 1.5,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: medicalBlue, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: sosRed),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: sosRed,
        brightness: Brightness.dark,
        primary: sosRed,
        surface: bgDark,
      ),
      scaffoldBackgroundColor: bgDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: cardDark,
        foregroundColor: textLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textLight,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderDark, width: 1),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        contentPadding:
            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: medicalBlue, width: 2),
        ),
      ),
    );
  }
}
