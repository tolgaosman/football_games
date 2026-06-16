import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/states.dart';

/// Shared "Coming Soon" placeholder used by the not-yet-built games.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    super.key,
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title.toUpperCase())),
      body: EmptyState(
        icon: icon,
        iconColor: AppColors.pitchGreen,
        title: 'COMING SOON',
        message: "We're lacing up the boots for this one.\nCheck back soon.",
      ),
    );
  }
}
