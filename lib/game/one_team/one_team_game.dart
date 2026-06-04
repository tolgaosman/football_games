import 'dart:math';

import '../../data/footballer_pool.dart';
import '../../data/player.dart';
import '../xox/factor_pool.dart';

/// Pure game logic for **1 Team 1 Country**.
///
/// One club is drawn from [FactorPool.teams] and one nationality from
/// [FactorPool.nationalities]; the "answer" to a round is the set of footballers
/// in [FootballerPool] who played for that club AND hold that nationality. All
/// data is local — there is no network layer.
class OneTeamGame {
  OneTeamGame._();

  /// The pool of clubs that can appear in the team slot (43 canonical clubs).
  static List<String> get teams => FactorPool.teams;

  /// The pool of nationalities that can appear in the country slot.
  static List<String> get nationalities => FactorPool.nationalities;

  /// Footballers who played for [team] and hold [nationality], sorted by name.
  static List<Player> matchingPlayers(String team, String nationality) {
    final result = FootballerPool.all
        .where((p) => p.teams.contains(team) && p.nationality == nationality)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  /// All (team, nationality) pairs that have at least one matching player. Built
  /// once and cached, since the pool is static.
  static final List<({String team, String nationality})> _validPairs =
      _buildValidPairs();

  static List<({String team, String nationality})> _buildValidPairs() {
    final pairs = <({String team, String nationality})>[];
    for (final team in teams) {
      for (final nationality in nationalities) {
        if (matchingPlayers(team, nationality).isNotEmpty) {
          pairs.add((team: team, nationality: nationality));
        }
      }
    }
    return pairs;
  }

  /// Whether any (team, nationality) pair with a matching player exists.
  static bool get hasAnyValidPair => _validPairs.isNotEmpty;

  /// A random (team, nationality) pair guaranteed to have a matching player.
  ///
  /// Falls back to the first club + first nationality if (defensively) none
  /// exists — the real pool always has many valid pairs.
  static ({String team, String nationality}) randomPair([Random? rng]) {
    if (_validPairs.isEmpty) {
      return (team: teams.first, nationality: nationalities.first);
    }
    final r = rng ?? Random();
    return _validPairs[r.nextInt(_validPairs.length)];
  }
}
