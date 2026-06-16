import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'animations.dart';

/// A centred loading indicator with optional caption — the single, consistent
/// loading treatment used across screens.
class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              color: AppColors.pitchGreen,
              strokeWidth: 3,
            ),
          ),
          if (message != null) ...[
            AppSpacing.gapLg,
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppTheme.caption(),
            ),
          ],
        ],
      ),
    );
  }
}

/// A polished empty / informational state: an icon, a title and a message,
/// gently animated in. Reused for "coming soon", "no results", etc.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.iconColor = AppColors.whiteMuted,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Color iconColor;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeSlideIn(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: iconColor),
              AppSpacing.gapLg,
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTheme.title(),
              ),
              if (message != null) ...[
                AppSpacing.gapSm,
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: AppTheme.body(color: AppColors.whiteMuted),
                ),
              ],
              if (action != null) ...[
                AppSpacing.gapXl,
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// An error state — same anatomy as [EmptyState] but tuned for failures
/// (danger-tinted icon, optional retry action).
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.icon = Icons.wifi_off_rounded,
    this.title = 'SOMETHING WENT WRONG',
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: icon,
      title: title,
      message: message,
      iconColor: AppColors.danger,
      action: action,
    );
  }
}
