import 'package:flutter/material.dart';

class AppTheme {
  // --- New Color Scheme: Red, Dark Bluish Green, and Black ---
  static const Color bgStart = Color(0xFF000000); // Pure Black (Background)
  static const Color bgEnd = Color(0xFF0A0A0A); // Dark Grey
  static const Color primary = Color(0xFF0F4C3A); // Dark Bluish Green (Primary Accent)
  static const Color accent = Color(0xFFDC2626); // Red (Secondary accent)
  static const Color mediumBluishGreen = Color(0xFF1B4332); // Medium Bluish Green
  static const Color lightBluishGreen = Color(0xFF2D5A47); // Light Bluish Green
  static const Color textMain = Color(0xFFF1F5F9); // Crisp Slate (Main Text)
  static const Color textFaint = Color(0xFF64748B); // Darker Cool Grey (Subtle/Hint Text)
  static const Color inputFill = Color(0xFF0A0A0A); // Black Input Slot Background
  static const Color cardBackground = Color(0xFF0A0A0A); // Card Background

  // --- 2. The Theme Data ---
  static final ThemeData stadiumNightTheme = ThemeData(
    brightness: Brightness.dark,
    // Base colors
    scaffoldBackgroundColor: bgStart,
    primaryColor: primary,

    // Text Styling
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: textMain),
      bodyMedium: TextStyle(color: Color(0xFF94A3B8)), // Cool Blue-Grey body text
      titleLarge: TextStyle(color: textMain, fontWeight: FontWeight.w900),
    ),

    // Input Fields (Applies Slot look globally)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputFill,
      hintStyle: const TextStyle(color: Color(0xFF475569)),
      labelStyle: const TextStyle(
          color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
      prefixIconColor: const Color(0xFF94A3B8),
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),

      // Border Styles (Sharp corners)
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(0)),
        borderSide: BorderSide(color: Color(0xFF333333), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(0),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(0)),
        borderSide: BorderSide(color: accent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(0),
        borderSide: const BorderSide(color: accent, width: 2),
      ),
    ),

    // Buttons (Applies Style globally)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: primary.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        padding: const EdgeInsets.symmetric(vertical: 18),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
  );
}
