import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Deep Space Color Palette
  static const Color background = Color(0xFF0F172A); // Deep Slate
  static const Color surface = Color(0xFF1E293B); // Dark Blue/Grey
  static const Color surfaceLight = Color(0xFF334155); // Lighter Surface
  
  static const Color primary = Color(0xFF6366F1); // Electric Indigo
  static const Color primaryVariant = Color(0xFF4F46E5);
  
  static const Color secondary = Color(0xFFEC4899); // Vibrant Pink
  static const Color tertiary = Color(0xFF06B6D4); // Cyan
  
  static const Color textPrimary = Color(0xFFF1F5F9); // Off-white
  static const Color textSecondary = Color(0xFF94A3B8); // Muted Blue/Grey

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        surface: surface,
        background: background,
        onBackground: textPrimary,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 40, // Reduced from 57
          fontWeight: FontWeight.bold,
        ),
        displayMedium: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 32, // Reduced from 45
          fontWeight: FontWeight.bold,
        ),
        displaySmall: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 28, // Reduced from 36
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 26, // Reduced from 32
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 24, // Reduced from 28
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 20, // Reduced from 24
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 18, // Reduced from 22
          fontWeight: FontWeight.w500,
        ),
        titleMedium: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 16, // Consistent
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
        ),
        titleSmall: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        bodyLarge: GoogleFonts.outfit( // Switched to Outfit
          color: textPrimary,
          fontSize: 14, // Reduced from 16
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
        bodyMedium: GoogleFonts.outfit( // Switched to Outfit
          color: textSecondary,
          fontSize: 12, // Reduced from 14
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
        ),
        labelLarge: GoogleFonts.outfit( // Switched to Outfit
          color: primary,
          fontSize: 12, // Reduced from 14
          fontWeight: FontWeight.w500,
          letterSpacing: 1.25,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      iconTheme: const IconThemeData(
        color: textSecondary,
        size: 20, // Reduced from 24
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Reduced padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 14, // Reduced from 16
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16), // Reduced from 20
        hintStyle: GoogleFonts.outfit(color: textSecondary, fontSize: 14), // Switched to Outfit
      ),
    );
  }
}
