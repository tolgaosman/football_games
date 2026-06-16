import 'package:flutter/material.dart';

/// A widget that displays the main application logo.
class FlyballLogo extends StatelessWidget {
  final double size;

  const FlyballLogo({
    super.key,
    this.size = 110.0,
  });

  @override
  Widget build(BuildContext context) {
    return Image(
      image: const AssetImage('assets/images/flyball_app_logo.png'),
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
