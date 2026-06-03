import 'package:flutter/material.dart';

import 'routing/app_routes.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const FlyballApp());
}

/// Root widget for Flyball — a dark-mode neo-brutalist football trivia app.
class FlyballApp extends StatelessWidget {
  const FlyballApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flyball',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
