import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Spacing scale — a small, consistent set of gaps so layouts breathe the same
/// way everywhere. Prefer these over magic `SizedBox` / `EdgeInsets` numbers.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // Convenient gap widgets.
  static const SizedBox gapXs = SizedBox(height: xs, width: xs);
  static const SizedBox gapSm = SizedBox(height: sm, width: sm);
  static const SizedBox gapMd = SizedBox(height: md, width: md);
  static const SizedBox gapLg = SizedBox(height: lg, width: lg);
  static const SizedBox gapXl = SizedBox(height: xl, width: xl);
  static const SizedBox gapXxl = SizedBox(height: xxl, width: xxl);
}

/// Shared visual constants and the global [ThemeData] for Flyball.
///
/// The aesthetic is "Refined Neo-Brutalism": thick borders and hard (un-blurred)
/// drop shadows on hero/interactive elements, but layered with softer elevation,
/// a deliberate type scale and generous whitespace for a more considered feel.
class AppTheme {
  AppTheme._();

  /// Standard thick border width for brutalist elements.
  static const double borderWidth = 3.5;

  /// A lighter border for quiet outlines.
  static const double hairlineWidth = 2.0;

  /// Standard blocky corner radius.
  static const double radius = 16.0;

  /// A smaller radius for chips / compact elements.
  static const double radiusSm = 10.0;

  /// Default resting hard-shadow offset for raised elements.
  static const Offset shadowOffset = Offset(6, 6);

  // ---- Motion ---------------------------------------------------------------

  static const Duration durFast = Duration(milliseconds: 140);
  static const Duration durMed = Duration(milliseconds: 280);
  static const Duration durSlow = Duration(milliseconds: 440);

  /// A lively settle for press/release micro-interactions.
  static const Curve springCurve = Curves.easeOutBack;

  /// A smooth, organic curve for entrances and transitions.
  static const Curve emphasized = Curves.easeOutCubic;

  // ---- Shadows --------------------------------------------------------------

  /// A solid (no-blur) hard shadow — the brutalist signature. Reserve for
  /// hero / interactive elements (buttons, headers, result banners).
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

  /// A softer, blurred elevation for non-hero surfaces (cards, sheets) so the
  /// layout gains depth without everything shouting.
  static List<BoxShadow> softShadow({double elevation = 1}) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.45),
        offset: Offset(0, 4 * elevation),
        blurRadius: 16 * elevation,
        spreadRadius: 0,
      ),
    ];
  }

  // ---- Type scale -----------------------------------------------------------

  /// A bold geometric heading style based on Space Grotesk.
  static TextStyle heading(double size, {Color color = AppColors.textPrimary}) {
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
    Color color = AppColors.textPrimary,
    FontWeight weight = FontWeight.w600,
  }) {
    return GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.4,
      letterSpacing: 0.2,
    );
  }

  // Named scale — prefer these for consistent hierarchy.
  static TextStyle displayXL({Color color = AppColors.textPrimary}) =>
      heading(44, color: color).copyWith(fontWeight: FontWeight.w800, letterSpacing: -1);
  static TextStyle display({Color color = AppColors.textPrimary}) =>
      heading(34, color: color).copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8);
  static TextStyle title({Color color = AppColors.textPrimary}) => heading(24, color: color);
  static TextStyle headline({Color color = AppColors.textPrimary}) => heading(18, color: color);
  static TextStyle body({Color color = AppColors.textPrimary}) => label(15, color: color);
  static TextStyle caption({Color color = AppColors.whiteMuted}) =>
      label(13, color: color, weight: FontWeight.w500);

  /// Uppercase, tracked label for brutalist section headers / eyebrows.
  static TextStyle overline({Color color = AppColors.whiteMuted}) {
    return GoogleFonts.spaceGrotesk(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: color,
      height: 1.2,
      letterSpacing: 1.6,
    );
  }

  // ---- ThemeData ------------------------------------------------------------

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
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.pitchGreen, size: 28),
        titleTextStyle: heading(24),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceHigh,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      splashColor: AppColors.pitchGreen.withValues(alpha: 0.15),
      highlightColor: Colors.transparent,
    );
  }
}
