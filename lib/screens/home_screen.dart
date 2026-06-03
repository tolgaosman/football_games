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
                    vertical: 32,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      const FlyballLogo(size: 170),
                      const SizedBox(height: 18),
                      // Wordmark.
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'FLY',
                              style: AppTheme.heading(46,
                                  color: AppColors.white),
                            ),
                            TextSpan(
                              text: 'BALL',
                              style: AppTheme.heading(46,
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
                      const SizedBox(height: 44),
                      _GameButton(
                        label: 'FOOTBALL XOX',
                        icon: Icons.grid_3x3_rounded,
                        onPressed: () => Navigator.of(context)
                            .pushNamed(AppRoutes.footballXox),
                      ),
                      const SizedBox(height: 22),
                      _GameButton(
                        label: 'FOOTBALLDLE',
                        icon: Icons.abc_rounded,
                        color: AppColors.surface,
                        foregroundColor: AppColors.white,
                        borderColor: AppColors.pitchGreen,
                        onPressed: () => Navigator.of(context)
                            .pushNamed(AppRoutes.footballdle),
                      ),
                      const SizedBox(height: 22),
                      _GameButton(
                        label: '1 TEAM 1 COUNTRY',
                        icon: Icons.public_rounded,
                        color: AppColors.surface,
                        foregroundColor: AppColors.white,
                        borderColor: AppColors.pitchGreen,
                        onPressed: () => Navigator.of(context)
                            .pushNamed(AppRoutes.oneTeamOneCountry),
                      ),
                      const SizedBox(height: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
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
