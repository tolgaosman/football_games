import 'package:flutter/material.dart';

/// Centralised colour palette for the Flyball neo-brutalist design system.
///
/// Deep charcoal backgrounds, a single vibrant "Pitch Green" accent and sharp
/// white text. Shadows are solid (no blur) to achieve the hard, blocky look.
class AppColors {
  AppColors._();

  /// Primary app background — deep charcoal / near-black.
  static const Color background = Color(0xFF121212);

  /// Slightly raised surface for cards and sheets.
  static const Color surface = Color(0xFF1C1C1C);

  /// A darker surface used for inset / empty states.
  static const Color surfaceLow = Color(0xFF0A0A0A);

  /// Vibrant neon "Pitch Green" accent.
  static const Color pitchGreen = Color(0xFF39FF14);

  /// A dimmer green for secondary accents / disabled states.
  static const Color pitchGreenDim = Color(0xFF1F8A0C);

  /// Sharp white for primary text and high-contrast borders.
  static const Color white = Color(0xFFFFFFFF);

  /// Muted white for secondary text.
  static const Color whiteMuted = Color(0xFFB5B5B5);

  /// Pure black, used for hard shadows and thick borders.
  static const Color black = Color(0xFF000000);

  /// Warning / error red used sparingly (e.g. network errors).
  static const Color danger = Color(0xFFFF3B3B);
}
