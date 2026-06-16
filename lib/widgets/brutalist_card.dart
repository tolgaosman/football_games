import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A blocky container with a thick border and a hard (un-blurred) drop shadow.
///
/// The shared building block for the neo-brutalist look. Used for grid cells,
/// sheet surfaces, list rows, etc.
class BrutalistCard extends StatelessWidget {
  const BrutalistCard({
    super.key,
    required this.child,
    this.color = AppColors.surface,
    this.borderColor = AppColors.white,
    this.shadowColor = AppColors.black,
    this.borderWidth = AppTheme.borderWidth,
    this.radius = AppTheme.radius,
    this.shadowOffset = AppTheme.shadowOffset,
    this.soft = false,
    this.elevation = 1,
    this.padding,
    this.width,
    this.height,
    this.alignment,
  });

  final Widget child;
  final Color color;
  final Color borderColor;
  final Color shadowColor;
  final double borderWidth;
  final double radius;
  final Offset shadowOffset;

  /// When true the card uses a soft, blurred elevation instead of the hard
  /// brutalist drop shadow — for quieter, layered surfaces.
  final bool soft;

  /// Relative depth of the soft elevation (ignored unless [soft] is true).
  final double elevation;

  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  List<BoxShadow>? get _shadow {
    if (soft) return AppTheme.softShadow(elevation: elevation);
    if (shadowOffset == Offset.zero) return null;
    return AppTheme.hardShadow(offset: shadowOffset, color: shadowColor);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: alignment,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: _shadow,
      ),
      child: child,
    );
  }
}
