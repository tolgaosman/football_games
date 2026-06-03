import 'package:flutter/material.dart';

import 'coming_soon_screen.dart';

/// Placeholder screen for the future "Footballdle" word-guessing game.
class FootballdleScreen extends StatelessWidget {
  const FootballdleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      title: 'Footballdle',
      icon: Icons.abc_rounded,
    );
  }
}
