import 'dart:math';

import '../../data/player.dart';
import '../xox/factor_pool.dart';

/// Pure game logic for **1 Team 1 Country**.
///
/// One club is drawn from [FactorPool.teams] and one nationality from
/// [FactorPool.nationalities]; the "answer" to a round is the set of footballers
/// in the injected corpus who played for that club AND hold that nationality.
/// The corpus is supplied by the screen (loaded from the on-device player
/// database, falling back to an empty corpus) — there is no network layer here.
class OneTeamGame {
  OneTeamGame(this._players) {
    _validPairs = _buildValidPairs();
  }

  final List<Player> _players;

  /// The pool of clubs that can appear in the team slot (canonical clubs).
  static List<String> get teams => FactorPool.teams;

  /// The pool of nationalities that can appear in the country slot.
  static List<String> get nationalities => FactorPool.nationalities;

  /// Footballers who played for [team] and hold [nationality], sorted by name.
  List<Player> matchingPlayers(String team, String nationality) {
    final result = _players
        .where((p) => p.teams.contains(team) && p.nationality == nationality)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  /// All (team, nationality) pairs that have at least one matching player. Built
  /// once in the constructor, since the corpus is fixed for a game instance.
  late final List<({String team, String nationality})> _validPairs;

  List<({String team, String nationality})> _buildValidPairs() {
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
  bool get hasAnyValidPair => _validPairs.isNotEmpty;

  /// A random (team, nationality) pair guaranteed to have a matching player.
  ///
  /// Falls back to the first club + first nationality if (defensively) none
  /// exists — a populated corpus always has many valid pairs.
  ({String team, String nationality}) randomPair([Random? rng]) {
    if (_validPairs.isEmpty) {
      return (team: teams.first, nationality: nationalities.first);
    }
    final r = rng ?? Random();
    return _validPairs[r.nextInt(_validPairs.length)];
  }
}
