import 'package:flutter/material.dart';
import 'theme_manager.dart';

class AppColors {
  // ================= LIGHT (warm + airy) =================
  static const Color _lightBackground = Color(0xFFF3E3D0); // warm base
  static const Color _lightSurface = Color(0xFFD2C4B4); // cards
  static const Color _lightPrimary = Color(0xFF2F3E4E); // deep muted blue-gray (added for contrast)
  static const Color _lightSecondary = Color(0xFF81A6C6); // your soft blue
  static const Color _lightAccent = Color(0xFF5FA8D3); // slightly richer blue for actions

  // ================= DARK (dimmed + inverted feel) =================
  static const Color _darkBackground = Color(0xFF1A1C1E); // dimmed warm-black
  static const Color _darkSurface = Color(0xFF2A2D31); // lifted surface
  static const Color _darkPrimary = Color(0xFFEADFD3); // inverted from warm bg (soft light text)
  static const Color _darkSecondary = Color(0xFF9FBFD3); // desaturated version of #AACDDC
  static const Color _darkAccent = Color(0xFF7FB3D5); // lifted blue accent

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

  // ================= HABIT COLORS =================
  static const List<Color> palette = [
    Color(0xFF81A6C6), // base blue
    Color(0xFF5FA8D3), // accent blue
    Color(0xFFA3BE8C), // calm green (added)
    Color(0xFFD08770), // soft orange (added warmth)
    Color(0xFFB48EAD), // muted purple
  ];
}