import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class TwoTeamOnePlayerScreen extends StatelessWidget {
  const TwoTeamOnePlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('2 TEAM 1 PLAYER', style: AppTheme.heading(20)),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Center(
        child: Text(
          'Coming Soon',
          style: AppTheme.heading(24, color: AppColors.pitchGreen),
        ),
      ),
    );
  }
}
