import 'package:flutter/material.dart';
import 'theme_manager.dart';

class AppColors {
  // ================= LIGHT =================
  static const Color _lightBackground = Color(0xFFF8FAFC);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightPrimary = Color(0xFF0F172A); // Deep slate
  static const Color _lightSecondary = Color(0xFF64748B); // Muted slate
  static const Color _lightAccent = Color(0xFF22C55E); // Fresh green (habit success)

  // ================= DARK =================
  static const Color _darkBackground = Color(0xFF020617); // Almost black (cleaner than slate)
  static const Color _darkSurface = Color(0xFF0F172A); // Card surface
  static const Color _darkPrimary = Color(0xFFF1F5F9); // Soft white
  static const Color _darkSecondary = Color(0xFF94A3B8); // Muted text
  static const Color _darkAccent = Color(0xFF4ADE80); // Brighter green for dark

  // ================= SMART ACCESS =================
  static bool get _isDark => ThemeManager().isDarkMode;

  static Color get background =>
      _isDark ? _darkBackground : _lightBackground;

  static Color get surface =>
      _isDark ? _darkSurface : _lightSurface;

  static Color get primary =>
      _isDark ? _darkPrimary : _lightPrimary;

  static Color get secondary =>
      _isDark ? _darkSecondary : _lightSecondary;

  static Color get accent =>
      _isDark ? _darkAccent : _lightAccent;

  // ================= OPTIONAL HABIT COLORS =================
  static const List<Color> palette = [
    Color(0xFF22C55E), // Green (success)
    Color(0xFF06B6D4), // Cyan (fresh)
    Color(0xFF6366F1), // Indigo (focus)
    Color(0xFFF59E0B), // Amber (energy)
    Color(0xFFEF4444), // Red (intensity)
    Color(0xFFA855F7), // Purple (balance)
  ];
}