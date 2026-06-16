import 'package:flutter/material.dart';

import '../screens/football_xox_screen.dart';
import '../screens/footballdle_screen.dart';
import '../screens/home_screen.dart';
import '../screens/one_team_one_country_screen.dart';
import '../screens/two_team_one_player_screen.dart';
import '../screens/xox_lobby_screen.dart';

/// Named routes and the route generator for Flyball.
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String footballXoxLobby = '/football-xox-lobby';
  static const String footballXox = '/football-xox';
  static const String footballdle = '/footballdle';
  static const String oneTeamOneCountry = '/one-team-one-country';
  static const String twoTeamOnePlayer = '/two-team-one-player';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case footballXoxLobby:
        return _build(const XoxLobbyScreen());
      case footballXox:
        final args = settings.arguments;
        if (args is XoxLobbyResult) {
          return _build(FootballXoxScreen(
            playerXName: args.playerXName,
            playerOName: args.playerOName,
          ));
        }
        return _build(const FootballXoxScreen());
      case footballdle:
        return _build(const FootballdleScreen());
      case oneTeamOneCountry:
        return _build(const OneTeamOneCountryScreen());
      case twoTeamOnePlayer:
        return _build(const TwoTeamOnePlayerScreen());
      case home:
      default:
        return _build(const HomeScreen());
    }
  }

  static MaterialPageRoute<dynamic> _build(Widget child) {
    return MaterialPageRoute<dynamic>(builder: (_) => child);
  }
}
