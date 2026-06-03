import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A custom-painted, stylised abstract football "flying" through the air.
///
/// Rendered entirely with [CustomPaint]: a neon-green ball with bold white
/// pentagon panels, tilted in motion, trailing three speed lines. Used as the
/// Flyball brand mark on the home screen.
class FlyballLogo extends StatelessWidget {
  const FlyballLogo({super.key, this.size = 180});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _FlyballPainter()),
    );
  }
}

class _FlyballPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.58, size.height * 0.42);
    final radius = size.shortestSide * 0.30;

    // --- Motion speed lines trailing behind the ball (top-left). ---
    final speedPaint = Paint()
      ..color = AppColors.pitchGreen
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final trail = [
      [0.06, 0.30, 0.34, 0.30, 7.0],
      [0.02, 0.46, 0.30, 0.46, 5.0],
      [0.10, 0.62, 0.34, 0.62, 4.0],
    ];
    for (final line in trail) {
      speedPaint.strokeWidth = line[4];
      canvas.drawLine(
        Offset(size.width * line[0], size.height * line[1]),
        Offset(size.width * line[2], size.height * line[3]),
        speedPaint,
      );
    }

    // --- Hard offset shadow disc for the brutalist depth. ---
    final shadowPaint = Paint()..color = AppColors.black;
    canvas.drawCircle(center.translate(6, 6), radius, shadowPaint);

    // --- Ball body. ---
    final ballPaint = Paint()..color = AppColors.pitchGreen;
    canvas.drawCircle(center, radius, ballPaint);

    // Thick outline.
    final outline = Paint()
      ..color = AppColors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.14;
    canvas.drawCircle(center, radius, outline);

    // --- Central white pentagon panel. ---
    final panelPaint = Paint()..color = AppColors.white;
    final panelStroke = Paint()
      ..color = AppColors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.10
      ..strokeJoin = StrokeJoin.round;

    final pentagon = _pentagonPath(center, radius * 0.46, rotation: -math.pi / 2);
    canvas.drawPath(pentagon, panelPaint);
    canvas.drawPath(pentagon, panelStroke);

    // --- Three small connecting white nubs (hexagon hint) at pentagon points. ---
    final nubPaint = Paint()..color = AppColors.white;
    for (int i = 0; i < 5; i += 2) {
      final angle = -math.pi / 2 + i * (2 * math.pi / 5);
      final p = center +
          Offset(math.cos(angle), math.sin(angle)) * (radius * 0.80);
      canvas.drawCircle(p, radius * 0.13, nubPaint);
      canvas.drawCircle(p, radius * 0.13, panelStroke);
    }
  }

  Path _pentagonPath(Offset center, double r, {double rotation = 0}) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = rotation + i * (2 * math.pi / 5);
      final point = center + Offset(math.cos(angle), math.sin(angle)) * r;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
