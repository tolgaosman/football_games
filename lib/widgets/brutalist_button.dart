import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A blocky, satisfying-to-press neo-brutalist button.
///
/// At rest it floats above a hard shadow. On press it translates down/right into
/// the shadow and dips in scale; on release it settles back with a lively spring
/// — giving the tactile "pressed into the page" feel. A light haptic fires on tap.
class BrutalistButton extends StatefulWidget {
  const BrutalistButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color = AppColors.pitchGreen,
    this.foregroundColor = AppColors.black,
    this.borderColor = AppColors.black,
    this.shadowColor = AppColors.black,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
    this.radius = AppTheme.radius,
    this.restingOffset = AppTheme.shadowOffset,
    this.expand = true,
    this.haptics = true,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final Color foregroundColor;
  final Color borderColor;
  final Color shadowColor;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Offset restingOffset;

  /// When true the button stretches to fill its parent's width.
  final bool expand;

  /// Fire a light selection haptic on tap.
  final bool haptics;

  @override
  State<BrutalistButton> createState() => _BrutalistButtonState();
}

class _BrutalistButtonState extends State<BrutalistButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppTheme.durFast,
    reverseDuration: AppTheme.durMed,
  );

  late final Animation<double> _press = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
    reverseCurve: AppTheme.springCurve,
  );

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (!_enabled) return;
    if (value) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color faceColor =
        _enabled ? widget.color : AppColors.pitchGreenDim.withValues(alpha: 0.4);

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: _enabled
          ? () {
              if (widget.haptics) HapticFeedback.selectionClick();
              widget.onPressed!();
            }
          : null,
      child: AnimatedBuilder(
        animation: _press,
        builder: (context, child) {
          final t = _press.value;
          final offset = Offset.lerp(widget.restingOffset, Offset.zero, t)!;
          final translation =
              Offset.lerp(Offset.zero, widget.restingOffset, t)!;
          final scale = 1 - 0.03 * t;

          return Transform.translate(
            offset: translation,
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: widget.expand ? double.infinity : null,
                decoration: BoxDecoration(
                  color: faceColor,
                  borderRadius: BorderRadius.circular(widget.radius),
                  border: Border.all(
                      color: widget.borderColor, width: AppTheme.borderWidth),
                  boxShadow: offset.distance < 0.5
                      ? null
                      : AppTheme.hardShadow(
                          offset: offset, color: widget.shadowColor),
                ),
                padding: widget.padding,
                child: child,
              ),
            ),
          );
        },
        child: DefaultTextStyle.merge(
          style: AppTheme.heading(20, color: widget.foregroundColor),
          textAlign: TextAlign.center,
          child: IconTheme.merge(
            data: IconThemeData(color: widget.foregroundColor),
            child:
                Center(widthFactor: widget.expand ? null : 1, child: widget.child),
          ),
        ),
      ),
    );
  }
}
