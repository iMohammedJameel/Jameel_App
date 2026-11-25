// lib/shared/styles/app_design.dart
//
// Single source of truth for the Jameel visual language.
// Every screen should pull colors / shadows / radii from here (or the
// theme-aware `AppThemeColors` extension on BuildContext) instead of
// hard-coding values, so a future re-brand is a one-file change.
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFFD92B2F);
  static const Color primaryDark = Color(0xFF9E1B1F);
  static const Color primarySoft = Color(0xFFFDECEC);
  static const Color primarySoftDark = Color(0xFF3A1A1D);

  // Light Neutrals
  static const Color background = Color(0xFFF6F7FB);
  static const Color surface = Colors.white;
  static const Color ink = Color(0xFF1A1C27);
  static const Color muted = Color(0xFF6B7280);
  static const Color border = Color(0xFFE8EAF1);
  static const Color toggleTrack = Color(0xFFECEEF4);
  static const Color unreadTint = Color(0xFFFFFAFA);

  // Dark Neutrals
  static const Color darkBackground = Color(0xFF0F1117);
  static const Color darkSurface = Color(0xFF171B24);
  static const Color darkInk = Color(0xFFF3F4F6);
  static const Color darkMuted = Color(0xFF9CA3AF);
  static const Color darkBorder = Color(0xFF262B38);
  static const Color darkToggleTrack = Color(0xFF222736);
  static const Color darkUnreadTint = Color(0xFF24171A);

  // Semantic
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF2563EB);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE53935), Color(0xFF9E1B1F)],
  );
}

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x14101828),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> brand = [
    BoxShadow(
      color: Color(0x4DD92B2F),
      blurRadius: 20,
      offset: Offset(0, 10),
    ),
  ];
}

extension AppThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bgColor => isDark ? AppColors.darkBackground : AppColors.background;
  Color get surfaceColor => isDark ? AppColors.darkSurface : AppColors.surface;
  Color get inkColor => isDark ? AppColors.darkInk : AppColors.ink;
  Color get mutedColor => isDark ? AppColors.darkMuted : AppColors.muted;
  Color get borderColor => isDark ? AppColors.darkBorder : AppColors.border;
  Color get toggleTrackColor =>
      isDark ? AppColors.darkToggleTrack : AppColors.toggleTrack;
  Color get unreadTintColor =>
      isDark ? AppColors.darkUnreadTint : AppColors.unreadTint;
  Color get primarySoftColor =>
      isDark ? AppColors.primarySoftDark : AppColors.primarySoft;
}
