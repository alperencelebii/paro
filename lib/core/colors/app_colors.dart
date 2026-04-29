import 'package:flutter/material.dart';

/// PARO Cüzdan brand color system.
abstract class AppColors {
  /// Core neutral colors.
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Color(0x00000000);

  /// Brand primary: trust / fintech blue.
  static const Color primary = Color(0xFF1D4ED8);

  /// Darker primary for pressed/hover states.
  static const Color primaryDark = Color(0xFF1E40AF);

  /// Disabled/soft primary.
  static const Color primarySoft = Color(0xFF93C5FD);

  /// Money / positive accent.
  static const Color accent = Color(0xFF22C55E);

  /// Logo and hero gradient start.
  static const Color gradientStart = Color(0xFF06B6D4);

  /// Logo and hero gradient end.
  static const Color gradientEnd = Color(0xFF22C55E);

  /// Status colors.
  static const Color income = Color(0xFF22C55E);
  static const Color expense = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color neutral = Color(0xFF64748B);

  /// Dark mode palette.
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkText = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  /// Light mode palette.
  static const Color lightBackground = Color(0xFFF9FAFB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightText = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF6B7280);

  /// Backward-compatible aliases used in older widgets.
  static const Color background = darkBackground;
  static const Color lightBlue = Color(0xFF60A5FA);
  static const Color blue = primary;
  static const Color deepBlue = primary;
  static const MaterialColor green = Colors.green;
  static const Color orangeAccent = warning;
  static const Color orange = warning;
  static const Color borderOutline = darkBorder;
  static const Color lightDark = darkTextSecondary;
  static const Color dark = darkSurface;
  static const Color primaryDarkBlue = darkBackground;
  static const Color grey = neutral;
  static const Color brightGrey = lightBackground;
  static const Color darkGrey = darkSurface;
  static const Color emphasizeGrey = lightTextSecondary;
  static const Color emphasizeDarkGrey = darkBackground;
  static const MaterialColor red = Colors.red;
}
