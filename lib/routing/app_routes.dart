import 'package:flutter/material.dart';

import '../screens/football_xox_screen.dart';
import '../screens/footballdle_screen.dart';
import '../screens/home_screen.dart';
import '../screens/one_team_one_country_screen.dart';

/// Named routes and the route generator for Flyball.
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String footballXox = '/football-xox';
  static const String footballdle = '/footballdle';
  static const String oneTeamOneCountry = '/one-team-one-country';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case footballXox:
        return _build(const FootballXoxScreen());
      case footballdle:
        return _build(const FootballdleScreen());
      case oneTeamOneCountry:
        return _build(const OneTeamOneCountryScreen());
      case home:
      default:
        return _build(const HomeScreen());
    }
  }

  static MaterialPageRoute<dynamic> _build(Widget child) {
    return MaterialPageRoute<dynamic>(builder: (_) => child);
  }
}
