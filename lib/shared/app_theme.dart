// lib/shared/app_theme.dart
//
// Material 3 light & dark themes built on top of the Jameel design tokens and
// locale-aware Google Fonts (Cairo for Arabic, Plus Jakarta Sans for English).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jameel/shared/styles/app_design.dart';

ThemeData buildAppTheme(
  Brightness brightness, {
  String languageCode = 'en',
}) {
  final isDark = brightness == Brightness.dark;
  final bg = isDark ? AppColors.darkBackground : AppColors.background;
  final surface = isDark ? AppColors.darkSurface : AppColors.surface;
  final ink = isDark ? AppColors.darkInk : AppColors.ink;
  final muted = isDark ? AppColors.darkMuted : AppColors.muted;
  final border = isDark ? AppColors.darkBorder : AppColors.border;
  final navIndicator =
      isDark ? AppColors.primarySoftDark : AppColors.primarySoft;

  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: brightness,
  ).copyWith(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    surface: surface,
    onSurface: ink,
    outline: border,
  );

  final base = ThemeData(useMaterial3: true, brightness: brightness);
  final fontTextTheme = languageCode == 'ar'
      ? GoogleFonts.cairoTextTheme(base.textTheme)
      : GoogleFonts.plusJakartaSansTextTheme(base.textTheme);

  final styledTextTheme = fontTextTheme.apply(
    bodyColor: ink,
    displayColor: ink,
  );

  final titleStyle = (languageCode == 'ar'
          ? GoogleFonts.cairo()
          : GoogleFonts.plusJakartaSans())
      .copyWith(
    color: ink,
    fontSize: 19,
    fontWeight: FontWeight.w800,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    textTheme: styledTextTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: ink),
      titleTextStyle: titleStyle,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 70,
      indicatorColor: navIndicator,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return (languageCode == 'ar'
                ? GoogleFonts.cairo()
                : GoogleFonts.plusJakartaSans())
            .copyWith(
          fontSize: 11.5,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: selected ? AppColors.primary : muted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 24,
          color: selected ? AppColors.primary : muted,
        );
      }),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerColor: border,
  );
}

final ThemeData lightTheme = buildAppTheme(Brightness.light);
final ThemeData darkTheme = buildAppTheme(Brightness.dark);
