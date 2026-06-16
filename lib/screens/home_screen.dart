import 'package:flutter/material.dart';

import '../routing/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
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
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.xl,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      const FadeSlideIn(
                        offset: Offset(0, 0.18),
                        child: FlyballLogo(size: 110),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Wordmark.
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 80),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'FLY',
                                style: AppTheme.displayXL(color: AppColors.white),
                              ),
                              TextSpan(
                                text: 'BALL',
                                style: AppTheme.displayXL(
                                    color: AppColors.pitchGreen),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 140),
                        child: Text(
                          'FOOTBALL TRIVIA, REIMAGINED',
                          style: AppTheme.overline(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      ..._buildGameButtons(context),
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

  List<Widget> _buildGameButtons(BuildContext context) {
    final buttons = <_GameButton>[
      _GameButton(
        label: 'FOOTBALL XOX',
        icon: Icons.grid_3x3_rounded,
        onPressed: () async {
          final result = await Navigator.of(context)
              .pushNamed(AppRoutes.footballXoxLobby);
          if (!context.mounted || result == null) return;
          Navigator.of(context).pushNamed(
            AppRoutes.footballXox,
            arguments: result,
          );
        },
      ),
      _GameButton(
        label: '2 TEAM 1 PLAYER',
        icon: Icons.people_alt_rounded,
        color: AppColors.surface,
        foregroundColor: AppColors.white,
        borderColor: AppColors.pitchGreen,
        onPressed: () =>
            Navigator.of(context).pushNamed(AppRoutes.twoTeamOnePlayer),
      ),
      _GameButton(
        label: 'FOOTBALLDLE',
        icon: Icons.abc_rounded,
        color: AppColors.surface,
        foregroundColor: AppColors.white,
        borderColor: AppColors.pitchGreen,
        onPressed: () =>
            Navigator.of(context).pushNamed(AppRoutes.footballdle),
      ),
      _GameButton(
        label: '1 TEAM 1 COUNTRY',
        icon: Icons.public_rounded,
        color: AppColors.surface,
        foregroundColor: AppColors.white,
        borderColor: AppColors.pitchGreen,
        onPressed: () =>
            Navigator.of(context).pushNamed(AppRoutes.oneTeamOneCountry),
      ),
    ];

    final widgets = <Widget>[];
    for (var i = 0; i < buttons.length; i++) {
      if (i > 0) widgets.add(const SizedBox(height: AppSpacing.md));
      widgets.add(
        FadeSlideIn(
          delay: Duration(milliseconds: 200 + i * 70),
          child: buttons[i],
        ),
      );
    }
    return widgets;
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
