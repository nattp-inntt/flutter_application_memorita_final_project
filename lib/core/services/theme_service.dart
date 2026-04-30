import 'package:flutter/material.dart';

class ThemeService {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(
    ThemeMode.dark,
  );

  static bool get isDarkMode => themeMode.value == ThemeMode.dark;

  static void toggleTheme(bool darkMode) {
    themeMode.value = darkMode ? ThemeMode.dark : ThemeMode.light;
  }
}
