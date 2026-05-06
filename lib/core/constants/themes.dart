import 'package:flutter/material.dart';

// ── Per-screen background colors ──────────────────────────────────────────────
// Use these in each screen's Scaffold backgroundColor
class AppColors {
  // Dark mode per-screen backgrounds
  static const darkDashboard  = Color(0xFF1A1A2E); // deep navy
  static const darkTimeline   = Color(0xFF1C1C2A); // dark slate
  static const darkSearch     = Color(0xFF1B1B28); // near-black purple
  static const darkSettings   = Color(0xFF1E1E2E); // base dark
  static const darkStats      = Color(0xFF1A1E2E); // dark blue-grey
  static const darkAddMemory  = Color(0xFF1C1A2E); // deep violet tint

  // Light mode per-screen backgrounds
  static const lightDashboard = Color(0xFFF3F3FF); // soft lavender
  static const lightTimeline  = Color(0xFFF5F5FF); // near-white purple
  static const lightSearch    = Color(0xFFF4F6FF); // cool white
  static const lightSettings  = Color(0xFFF6F6FF); // base light
  static const lightStats     = Color(0xFFF0F4FF); // icy blue-white
  static const lightAddMemory = Color(0xFFF5F3FF); // warm lavender

  // Card colors
  static const darkCard  = Color(0xFF2A2A40);
  static const lightCard = Color(0xFFFFFFFF);

  // Primary accent
  static const primary = Color(0xFF6C63FF);
}

class AppTheme {
  // ── Dark theme ───────────────────────────────────────────────────────────────

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.darkDashboard,
      cardColor: AppColors.darkCard,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.darkCard,
        onSurface: Colors.white,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkDashboard,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        bodySmall: TextStyle(color: Colors.white54),
        titleLarge:
            TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        titleMedium:
            TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: Colors.white70),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        hintStyle: const TextStyle(color: Colors.white38),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
      ),

      iconTheme: const IconThemeData(color: Colors.white70),

      dividerColor: Colors.white,

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkDashboard,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.white54,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkCard,
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        labelStyle: const TextStyle(color: Colors.white70),
        side: const BorderSide(color: Colors.white12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  // ── Light theme ──────────────────────────────────────────────────────────────

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.lightDashboard,
      cardColor: AppColors.lightCard,

      colorScheme: const ColorScheme.light(
        primary: Color(0xFF6C63FF),
        surface: AppColors.lightCard,
        onSurface: Colors.black87,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightDashboard,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        iconTheme: IconThemeData(color: Colors.black87),
      ),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black54),
        bodySmall: TextStyle(color: Colors.black45),
        titleLarge: TextStyle(
            color: Colors.black87, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(
            color: Colors.black87, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: Colors.black54),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF2F2FF),
        hintStyle: const TextStyle(color: Colors.black38),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
      ),

      iconTheme: const IconThemeData(color: Colors.black87),

      dividerColor: Colors.black,

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightCard,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.black54,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF0F0FF),
        selectedColor: AppColors.primary.withValues(alpha: 0.12),
        labelStyle: const TextStyle(color: Colors.black87),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}