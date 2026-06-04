import 'package:flutter/material.dart';

class FlyballLogo extends StatelessWidget {
  const FlyballLogo({super.key, this.size = 180});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/flyball_app_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
