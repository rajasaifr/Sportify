import 'package:flutter/material.dart';

class AppTheme {
  // --- 1. The Neon Void Palette ---
  static const Color bgStart = Color(0xFF050505); // Pure Void (Background)
  static const Color bgEnd = Color(0xFF161616); // Dark Carbon
  static const Color primary =
      Color(0xFF8B5CF6); // Neon Violet (Primary Accent for buttons, links)
  static const Color accent =
      Color(0xFF00E5FF); // Cyan Punch (Secondary accent)
  static const Color textMain = Color(0xFFF1F5F9); // Crisp Slate (Main Text)
  static const Color textFaint =
      Color(0xFF64748B); // Darker Cool Grey (Subtle/Hint Text)
  static const Color inputFill =
      Color(0xFF0F0F0F); // Black Input Slot Background

  // --- 2. The Theme Data ---
  static final ThemeData stadiumNightTheme = ThemeData(
    brightness: Brightness.dark,
    // Base colors
    scaffoldBackgroundColor: bgStart,
    primaryColor: primary,

    // Text Styling
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: textMain),
      bodyMedium:
          TextStyle(color: Color(0xFF94A3B8)), // Cool Blue-Grey body text
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

      // Border Styles (for Neon Glow)
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: Color(0xFF333333), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 2), // Neon glow
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: Colors.redAccent, width: 1),
      ),
      // Ensure error border is visible when focused too
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    ),

    // Buttons (Applies Neon Style globally)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 10,
        shadowColor: primary.withOpacity(0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 18),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
  );
}
