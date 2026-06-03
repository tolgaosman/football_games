import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/brutalist_card.dart';

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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrutalistCard(
                color: AppColors.surface,
                borderColor: AppColors.pitchGreen,
                padding: const EdgeInsets.all(28),
                child: Icon(icon, size: 72, color: AppColors.pitchGreen),
              ),
              const SizedBox(height: 36),
              Text(
                'COMING SOON',
                textAlign: TextAlign.center,
                style: AppTheme.heading(40, color: AppColors.pitchGreen),
              ),
              const SizedBox(height: 14),
              Text(
                "We're lacing up the boots for this one.\nCheck back soon.",
                textAlign: TextAlign.center,
                style: AppTheme.label(15, color: AppColors.whiteMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
