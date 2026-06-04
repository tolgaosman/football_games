import 'dart:math';

import '../../data/footballer_pool.dart';
import '../../data/player.dart';
import '../xox/factor_pool.dart';

/// Pure game logic for **2 Team 1 Player**.
///
/// Two clubs are drawn from [FactorPool.teams]; the "answer" to a round is the
/// set of footballers in [FootballerPool] who played for BOTH clubs. All data is
/// local — there is no network layer.
class TwoTeamGame {
  TwoTeamGame._();

  /// The pool of clubs that can appear in the slots (the 43 canonical clubs).
  static List<String> get teams => FactorPool.teams;

  /// Footballers who played for BOTH [teamA] and [teamB], sorted by name.
  static List<Player> sharedPlayers(String teamA, String teamB) {
    final result = FootballerPool.all
        .where((p) => p.teams.contains(teamA) && p.teams.contains(teamB))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  /// All unordered club pairs that have at least one shared player. Built once
  /// and cached, since the pool is static.
  static final List<({String teamA, String teamB})> _validPairs =
      _buildValidPairs();

  static List<({String teamA, String teamB})> _buildValidPairs() {
    final pairs = <({String teamA, String teamB})>[];
    final all = teams;
    for (var i = 0; i < all.length; i++) {
      for (var j = i + 1; j < all.length; j++) {
        if (sharedPlayers(all[i], all[j]).isNotEmpty) {
          pairs.add((teamA: all[i], teamB: all[j]));
        }
      }
    }
    return pairs;
  }

  /// Whether any club pair with a shared player exists (defensive guard).
  static bool get hasAnyValidPair => _validPairs.isNotEmpty;

  /// A random club pair guaranteed to have at least one shared player.
  ///
  /// Falls back to the first two clubs if (defensively) no valid pair exists —
  /// the real pool always has hundreds of valid pairs.
  static ({String teamA, String teamB}) randomPair([Random? rng]) {
    if (_validPairs.isEmpty) {
      return (teamA: teams.first, teamB: teams.last);
    }
    final r = rng ?? Random();
    return _validPairs[r.nextInt(_validPairs.length)];
  }
}
