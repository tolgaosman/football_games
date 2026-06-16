import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' show databaseFactory;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'
    show databaseFactoryFfiWeb;

import 'routing/app_routes.dart';
import 'theme/app_theme.dart';
import 'widgets/phone_frame.dart';

void main() {
  // Required before any plugin / platform-channel use (sqflite, rootBundle).
  WidgetsFlutterBinding.ensureInitialized();

  // On web, plain sqflite has no backend; route it through the IndexedDB-backed
  // FFI web factory so the bundled player database loads. Mobile (Android/iOS)
  // keeps the built-in sqflite factory, so nothing changes there.
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

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
      builder: (context, child) {
        return PhoneFrame(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
