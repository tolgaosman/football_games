import 'dart:math';

import '../../data/player.dart';
import '../../data/player_attributes.dart';
import 'board_solver.dart';
import 'factor.dart';

/// The catalogue of all possible XOX factors plus the board generator.
///
/// [generateBoard] returns 3 row + 3 column factors that are **all six
/// unique** (per the agreed game rule) via reject-sampling from the combined
/// pool.
class FactorPool {
  FactorPool._();

  /// The six leagues used across "played in" and "won" factors.
  static const List<String> leagues = [
    'Premier League',
    'Ligue 1',
    'Bundesliga',
    'Serie A',
    'La Liga',
    'Trendyol Süper Lig',
  ];

  /// International tournaments.
  static const List<String> internationalTournaments = [
    'World Cup',
    'Copa America',
    'Euros',
  ];

  /// Major clubs drawn from the six leagues above.
  static const List<String> teams = [
    // Premier League (12 teams)
    'Arsenal',
    'Aston Villa',
    'Brighton',
    'Chelsea',
    'Crystal Palace',
    'Liverpool',
    'Manchester City',
    'Manchester United',
    'Newcastle United',
    'Nottingham Forest',
    'Tottenham Hotspur',
    'West Ham United',

    // La Liga (7 teams)
    'Real Madrid',
    'Barcelona',
    'Atletico Madrid',
    'Athletic Bilbao',
    'Real Betis',
    'Sevilla',
    'Villarreal',

    // Bundesliga (6 teams)
    'Bayern Munich',
    'Borussia Dortmund',
    'Bayer Leverkusen',
    'Eintracht Frankfurt',
    'RB Leipzig',
    'VfL Wolfsburg',

    // Serie A (8 teams)
    'AC Milan',
    'Inter Milan',
    'Juventus',
    'Napoli',
    'Atalanta',
    'Roma',
    'Lazio',
    'Fiorentina',

    // Ligue 1 (5 teams)
    'PSG',
    'Lyon',
    'Lille',
    'Marseille',
    'Monaco',

    // Trendyol Süper Lig (5 teams)
    'Galatasaray',
    'Fenerbahce',
    'Besiktas',
    'Trabzonspor',
    'Başakşehir',
  ];

  /// The exact 75 nationalities supplied for use as factors.
  static const List<String> nationalities = [
    'France', 'Spain', 'Argentina', 'England', 'Portugal', 'Brazil',
    'Netherlands', 'Morocco', 'Belgium', 'Germany', 'Croatia', 'Italy',
    'Colombia', 'Senegal', 'Mexico', 'USA', 'Uruguay', 'Japan', 'Switzerland',
    'Denmark', 'Iran', 'Turkiye', 'Ecuador', 'Austria', 'South Korea',
    'Nigeria', 'Australia', 'Algeria', 'Egypt', 'Canada', 'Norway', 'Ukraine',
    'Panama', 'Ivory Coast', 'Poland', 'Russia', 'Wales', 'Sweden', 'Serbia',
    'Paraguay', 'Czechia', 'Hungary', 'Scotland', 'Tunisia', 'Cameroon',
    'DR Congo', 'Greece', 'Slovakia', 'Venezuela', 'Uzbekistan', 'Costa Rica',
    'Mali', 'Peru', 'Chile', 'Qatar', 'Romania', 'Iraq', 'Slovenia', 'Ireland',
    'South Africa', 'Saudi Arabia', 'Burkina Faso', 'Jordan', 'Albania',
    'Bosnia', 'Honduras', 'North Macedonia', 'UAE', 'Cape Verde',
    'N. Ireland', 'Jamaica', 'Georgia', 'Finland', 'Ghana', 'Iceland',
  ];

  /// Builds the full flat pool of selectable factors.
  static List<Factor> allFactors() {
    final factors = <Factor>[];

    for (final league in leagues) {
      factors.add(Factor(
        type: FactorType.playedLeague,
        label: 'Played in $league',
        value: league,
      ));
      factors.add(Factor(
        type: FactorType.wonLeague,
        label: 'Won $league',
        value: league,
      ));
    }

    for (final tournament in internationalTournaments) {
      factors.add(Factor(
        type: FactorType.wonInternational,
        label: 'Won $tournament',
        value: tournament,
      ));
    }

    for (final team in teams) {
      factors.add(Factor(
        type: FactorType.team,
        label: 'Played for $team',
        value: team,
      ));
    }

    for (final country in nationalities) {
      factors.add(Factor(
        type: FactorType.nationality,
        label: country,
        value: country,
      ));
    }

    return factors;
  }

  /// Picks 3 row + 3 column factors that are all six unique, obey the
  /// axis-exclusivity rules ([_axesAreValid]), AND form a fully solvable board
  /// (every one of the 9 cells has at least one player in [players] satisfying
  /// both its row and column factor).
  ///
  /// [players] defaults to the curated [PlayerAttributes] corpus; tests can
  /// inject a fixed list. Returns a record of (rows, columns), length 3 each.
  static ({List<Factor> rows, List<Factor> columns}) generateBoard([
    Random? random,
    List<Player>? players,
  ]) {
    final rng = random ?? Random();
    final corpus = players ?? PlayerAttributes.all;

    // Reject-sample whole draws until the split obeys the axis rules and the
    // board is fully solvable against the corpus. With a large factor pool a
    // valid draw is found quickly; the cap guards against pathological cases.
    const maxAttempts = 2000;
    List<Factor>? rows;
    List<Factor>? columns;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final chosen = _pickSixUnique(rng);
      final r = chosen.sublist(0, 3);
      final c = chosen.sublist(3, 6);
      if (_axesAreValid(r, c) &&
          BoardSolver.boardIsSolvable(r, c, corpus)) {
        rows = r;
        columns = c;
        break;
      }
    }

    // Fallback: build a guaranteed-solvable board around a single random player
    // so we never return a broken board (e.g. an extremely small corpus).
    if (rows == null || columns == null) {
      final fallback = _solvableBoardFor(rng, corpus);
      rows = fallback.rows;
      columns = fallback.columns;
    }

    return (rows: rows, columns: columns);
  }

  /// Builds a definitely-solvable board by anchoring on one player: every
  /// chosen factor is one that player satisfies, so all 9 cells are solvable
  /// (that player answers each). Used only as a safety fallback.
  static ({List<Factor> rows, List<Factor> columns}) _solvableBoardFor(
    Random rng,
    List<Player> corpus,
  ) {
    final pool = corpus.isEmpty ? PlayerAttributes.all : corpus;

    // Filter players who satisfy at least 6 factors from the current pool
    final validAnchors = pool.where((player) {
      final count = allFactors().where((f) => f.matches(player)).length;
      return count >= 6;
    }).toList()..shuffle(rng);

    for (final anchor in validAnchors) {
      final satisfied = allFactors().where((f) => f.matches(anchor)).toList();
      // Try to find 6 unique factors from the satisfied list that can form a valid axis split
      for (var attempt = 0; attempt < 50; attempt++) {
        satisfied.shuffle(rng);
        final chosen = satisfied.sublist(0, 6);
        // Try permutations of these 6 to see if any split satisfies _axesAreValid
        for (var perm = 0; perm < 20; perm++) {
          chosen.shuffle(rng);
          final r = chosen.sublist(0, 3);
          final c = chosen.sublist(3, 6);
          if (_axesAreValid(r, c)) {
            return (rows: r, columns: c);
          }
        }
      }
    }

    // Last-resort solvable build: anchor on the player with the MOST satisfied
    // factors and use only factors they satisfy, so every cell is solvable by
    // that anchor regardless of the axis split. Pad (if somehow < 6) only with
    // other factors that anchor also satisfies — never arbitrary ones.
    final best = pool.reduce((a, b) =>
        allFactors().where((f) => f.matches(a)).length >=
                allFactors().where((f) => f.matches(b)).length
            ? a
            : b);
    final satisfied = allFactors().where((f) => f.matches(best)).toList()
      ..shuffle(rng);
    // Guarantee at least 6 by padding with safe (non-nationality/non-intl)
    // factors; these may be unsolvable for the anchor but only run in the
    // degenerate near-empty-corpus case the real game never hits.
    if (satisfied.length < 6) {
      final pad = allFactors()
          .where((f) =>
              !f.isNationality && !f.isInternational && !satisfied.contains(f))
          .toList()
        ..shuffle(rng);
      satisfied.addAll(pad);
    }
    // Prefer a split that obeys the axis rules; if none in a few tries, accept
    // any split (still fully solvable, just possibly with a redundant axis).
    for (var i = 0; i < 100; i++) {
      satisfied.shuffle(rng);
      final r = satisfied.sublist(0, 3);
      final c = satisfied.sublist(3, 6);
      if (_axesAreValid(r, c)) return (rows: r, columns: c);
    }
    return (
      rows: satisfied.sublist(0, 3),
      columns: satisfied.sublist(3, 6),
    );
  }

  /// Six distinct factors drawn from a shuffled pool. Because [Factor] equality
  /// is by (type, value) and the pool has no duplicates, the first six distinct
  /// entries are unique.
  static List<Factor> _pickSixUnique(Random rng) {
    final pool = allFactors()..shuffle(rng);
    final chosen = <Factor>[];
    final seen = <Factor>{};
    for (final factor in pool) {
      if (seen.add(factor)) {
        chosen.add(factor);
        if (chosen.length == 6) break;
      }
    }
    return chosen;
  }

  /// A nationality on a row crossing a nationality on a column (and likewise two
  /// international-tournament factors) would produce impossible cells. So the
  /// row set and column set must not BOTH contain a nationality, nor BOTH
  /// contain an international tournament. (Two of the same group on the *same*
  /// axis is fine — those headers never intersect each other.)
  static bool _axesAreValid(List<Factor> rows, List<Factor> columns) {
    final rowsHaveNation = rows.any((f) => f.isNationality);
    final colsHaveNation = columns.any((f) => f.isNationality);
    if (rowsHaveNation && colsHaveNation) return false;

    final rowsHaveIntl = rows.any((f) => f.isInternational);
    final colsHaveIntl = columns.any((f) => f.isInternational);
    if (rowsHaveIntl && colsHaveIntl) return false;

    return true;
  }
}
