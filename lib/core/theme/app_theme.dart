import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:milo/core/theme/app_colors.dart';

/// Thème global Milo : Néo-brutalisme + Glassmorphisme
abstract final class AppTheme {
  static ThemeData get dark {
    final baseText = GoogleFonts.spaceGroteskTextTheme(
      ThemeData.dark().textTheme,
    ).apply(
      bodyColor: AppColors.cream,
      displayColor: AppColors.cream,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDeep,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.yellowVivid,
        secondary: AppColors.yellowGold,
        surface: AppColors.backgroundSurface,
        onPrimary: AppColors.backgroundDeep,
        onSecondary: AppColors.backgroundDeep,
        onSurface: AppColors.cream,
        error: AppColors.error,
      ),
      textTheme: baseText.copyWith(
        displayLarge: GoogleFonts.syne(
          fontWeight: FontWeight.w800,
          color: AppColors.cream,
          fontSize: 40,
        ),
        displayMedium: GoogleFonts.syne(
          fontWeight: FontWeight.w700,
          color: AppColors.cream,
          fontSize: 32,
        ),
        headlineLarge: GoogleFonts.syne(
          fontWeight: FontWeight.w700,
          color: AppColors.cream,
          fontSize: 28,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w700,
          color: AppColors.cream,
          fontSize: 22,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w700,
          color: AppColors.cream,
          fontSize: 18,
        ),
        bodyLarge: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w500,
          color: AppColors.cream,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w400,
          color: AppColors.cream.withValues(alpha: 0.85),
          fontSize: 14,
        ),
        labelLarge: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w700,
          color: AppColors.backgroundDeep,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundDeep,
        foregroundColor: AppColors.cream,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.syne(
          fontWeight: FontWeight.w800,
          fontSize: 22,
          color: AppColors.cream,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundSurface,
        selectedItemColor: AppColors.yellowVivid,
        unselectedItemColor: AppColors.cream,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.yellowVivid,
        inactiveTrackColor: AppColors.backgroundSurface,
        thumbColor: AppColors.yellowGold,
        overlayColor: AppColors.yellowVivid.withValues(alpha: 0.2),
      ),
      dividerColor: AppColors.border,
      splashColor: AppColors.yellowVivid.withValues(alpha: 0.15),
      highlightColor: AppColors.yellowVivid.withValues(alpha: 0.08),
    );
  }
}
