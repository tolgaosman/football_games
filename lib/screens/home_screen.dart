import 'package:flutter/material.dart';

import '../routing/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/brutalist_button.dart';
import '../widgets/flyball_logo.dart';

/// The landing screen: the Flyball brand mark and the three game buttons.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      const FlyballLogo(size: 110),
                      const SizedBox(height: 14),
                      // Wordmark.
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'FLY',
                              style: AppTheme.heading(40,
                                  color: AppColors.white),
                            ),
                            TextSpan(
                              text: 'BALL',
                              style: AppTheme.heading(40,
                                  color: AppColors.pitchGreen),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'FOOTBALL TRIVIA, REIMAGINED',
                        style: AppTheme.label(13,
                            color: AppColors.whiteMuted,
                            weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 30),
                      _GameButton(
                        label: 'FOOTBALL XOX',
                        icon: Icons.grid_3x3_rounded,
                        onPressed: () => Navigator.of(context)
                            .pushNamed(AppRoutes.footballXox),
                      ),
                      const SizedBox(height: 12),
                      _GameButton(
                        label: '2 TEAM 1 PLAYER',
                        icon: Icons.people_alt_rounded,
                        color: AppColors.surface,
                        foregroundColor: AppColors.white,
                        borderColor: AppColors.pitchGreen,
                        onPressed: () => Navigator.of(context)
                            .pushNamed(AppRoutes.twoTeamOnePlayer),
                      ),
                      const SizedBox(height: 12),
                      _GameButton(
                        label: 'FOOTBALLDLE',
                        icon: Icons.abc_rounded,
                        color: AppColors.surface,
                        foregroundColor: AppColors.white,
                        borderColor: AppColors.pitchGreen,
                        onPressed: () => Navigator.of(context)
                            .pushNamed(AppRoutes.footballdle),
                      ),
                      const SizedBox(height: 12),
                      _GameButton(
                        label: '1 TEAM 1 COUNTRY',
                        icon: Icons.public_rounded,
                        color: AppColors.surface,
                        foregroundColor: AppColors.white,
                        borderColor: AppColors.pitchGreen,
                        onPressed: () => Navigator.of(context)
                            .pushNamed(AppRoutes.oneTeamOneCountry),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A massive blocky home button with an icon and label.
class _GameButton extends StatelessWidget {
  const _GameButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color = AppColors.pitchGreen,
    this.foregroundColor = AppColors.black,
    this.borderColor = AppColors.black,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final Color foregroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return BrutalistButton(
      onPressed: onPressed,
      color: color,
      foregroundColor: foregroundColor,
      borderColor: borderColor,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: foregroundColor),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.heading(24, color: foregroundColor),
            ),
          ),
        ],
      ),
    );
  }
}
