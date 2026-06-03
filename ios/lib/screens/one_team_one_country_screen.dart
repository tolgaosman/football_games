import 'package:flutter/material.dart';

import 'coming_soon_screen.dart';

/// Placeholder screen for the future "1 Team 1 Country" game.
class OneTeamOneCountryScreen extends StatelessWidget {
  const OneTeamOneCountryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      title: '1 Team 1 Country',
      icon: Icons.public_rounded,
    );
  }
}
