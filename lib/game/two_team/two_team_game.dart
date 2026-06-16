import 'dart:math';

import '../../data/player.dart';
import '../xox/factor_pool.dart';

/// Pure game logic for **2 Team 1 Player**.
///
/// Two clubs are drawn from [FactorPool.teams]; the "answer" to a round is the
/// set of footballers in the injected corpus who played for BOTH clubs. The
/// corpus is supplied by the screen (loaded from the on-device player database,
/// falling back to an empty corpus) — there is no network layer here.
class TwoTeamGame {
  TwoTeamGame(this._players) {
    _validPairs = _buildValidPairs();
  }

  final List<Player> _players;

  /// The pool of clubs that can appear in the slots (the canonical clubs).
  static List<String> get teams => FactorPool.teams;

  /// Footballers who played for BOTH [teamA] and [teamB], sorted by name.
  List<Player> sharedPlayers(String teamA, String teamB) {
    final result = _players
        .where((p) => p.teams.contains(teamA) && p.teams.contains(teamB))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  /// All unordered club pairs that have at least one shared player. Built once
  /// in the constructor, since the corpus is fixed for a game instance.
  late final List<({String teamA, String teamB})> _validPairs;

  List<({String teamA, String teamB})> _buildValidPairs() {
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
  bool get hasAnyValidPair => _validPairs.isNotEmpty;

  /// A random club pair guaranteed to have at least one shared player.
  ///
  /// Falls back to the first two clubs if (defensively) no valid pair exists —
  /// a populated corpus always has hundreds of valid pairs.
  ({String teamA, String teamB}) randomPair([Random? rng]) {
    if (_validPairs.isEmpty) {
      return (teamA: teams.first, teamB: teams.last);
    }
    final r = rng ?? Random();
    return _validPairs[r.nextInt(_validPairs.length)];
  }
}
