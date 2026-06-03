import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Shared visual constants and the global [ThemeData] for Flyball.
///
/// The aesthetic is "Dark-Mode Neo-Brutalism": thick borders, hard (un-blurred)
/// drop shadows, blocky rounded corners and a bold geometric sans-serif.
class AppTheme {
  AppTheme._();

  /// Standard thick border width for brutalist elements.
  static const double borderWidth = 3.5;

  /// Standard blocky corner radius.
  static const double radius = 16.0;

  /// Default resting hard-shadow offset for raised elements.
  static const Offset shadowOffset = Offset(6, 6);

  /// A solid (no-blur) hard shadow at the given [offset] and [color].
  static List<BoxShadow> hardShadow({
    Offset offset = shadowOffset,
    Color color = AppColors.black,
  }) {
    return [
      BoxShadow(
        color: color,
        offset: offset,
        blurRadius: 0,
        spreadRadius: 0,
      ),
    ];
  }

  /// A bold geometric text style based on Space Grotesk.
  static TextStyle heading(double size, {Color color = AppColors.white}) {
    return GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color,
      height: 1.05,
      letterSpacing: -0.5,
    );
  }

  /// Body / label text style.
  static TextStyle label(
    double size, {
    Color color = AppColors.white,
    FontWeight weight = FontWeight.w600,
  }) {
    return GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: 0.2,
    );
  }

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.pitchGreen,
        secondary: AppColors.pitchGreen,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme).apply(
        bodyColor: AppColors.white,
        displayColor: AppColors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.pitchGreen, size: 28),
        titleTextStyle: heading(24),
      ),
      splashColor: AppColors.pitchGreen.withValues(alpha: 0.15),
      highlightColor: Colors.transparent,
    );
  }
}
