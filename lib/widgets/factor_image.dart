import 'package:flutter/material.dart';

import '../game/xox/factor.dart';
import '../game/xox/factor_art.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Renders a [Factor] as its image (flag / league logo / team logo / trophy),
/// falling back to the factor's text label when no image is available or the
/// network image fails to load.
///
/// For "Won `<league>`" factors a small champion "#1" badge is stacked in the
/// corner so it reads differently from "Played in `<league>`".
class FactorImage extends StatelessWidget {
  const FactorImage({
    super.key,
    required this.factor,
    this.imageSize = 44,
    this.textColor = AppColors.black,
  });

  final Factor factor;

  /// Target edge length for the image (it is scaled to fit within this).
  final double imageSize;

  /// Colour for the text fallback (headers sit on pitch-green, so default
  /// black). Trophies/flags ignore this.
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final art = FactorArtResolver.forFactor(factor);
    if (!art.hasImage) return _fallbackText();

    final Widget image = art.assetPath != null
        ? Image.asset(
            art.assetPath!,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => _fallbackText(),
          )
        : Image.network(
            art.networkUrl!,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => _fallbackText(),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.black,
                  ),
                ),
              );
            },
          );

    final sized = SizedBox(
      width: imageSize,
      height: imageSize,
      child: Center(child: image),
    );

    if (!art.isWonLeague) return sized;

    // "Won <league>" = the league logo with a cup emoji beside it (champion).
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: sized),
        SizedBox(width: imageSize * 0.08),
        Text('🏆', style: TextStyle(fontSize: imageSize * 0.42)),
      ],
    );
  }

  /// Readable text fallback that fills the header cell and wraps, used when no
  /// image is available or an image fails to load.
  Widget _fallbackText() {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            factor.label,
            textAlign: TextAlign.center,
            maxLines: 3,
            style: AppTheme.label(15, color: textColor, weight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
