import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A blocky, satisfying-to-press neo-brutalist button.
///
/// At rest it floats above a hard shadow. On press it translates down/right by
/// the shadow offset while the shadow shrinks to zero — giving the tactile
/// "pressed into the page" feel.
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

  @override
  State<BrutalistButton> createState() => _BrutalistButtonState();
}

class _BrutalistButtonState extends State<BrutalistButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (!_enabled) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final offset = _pressed ? Offset.zero : widget.restingOffset;
    final translation =
        _pressed ? widget.restingOffset : Offset.zero;

    final Color faceColor =
        _enabled ? widget.color : AppColors.pitchGreenDim.withValues(alpha: 0.4);

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(translation.dx, translation.dy, 0),
        width: widget.expand ? double.infinity : null,
        decoration: BoxDecoration(
          color: faceColor,
          borderRadius: BorderRadius.circular(widget.radius),
          border: Border.all(color: widget.borderColor, width: AppTheme.borderWidth),
          boxShadow: offset == Offset.zero
              ? null
              : AppTheme.hardShadow(offset: offset, color: widget.shadowColor),
        ),
        padding: widget.padding,
        child: DefaultTextStyle.merge(
          style: AppTheme.heading(20, color: widget.foregroundColor),
          textAlign: TextAlign.center,
          child: IconTheme.merge(
            data: IconThemeData(color: widget.foregroundColor),
            child: Center(widthFactor: widget.expand ? null : 1, child: widget.child),
          ),
        ),
      ),
    );
  }
}
