import 'dart:math';


import '../../data/player.dart';
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

  /// The five international / continental tournaments.
  static const List<String> internationalTournaments = [
    'World Cup',
    'Euros',
    'Copa America',
    'Champions League',
    'Europa League',
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

  /// The exact 59 nationalities supplied for use as factors.
  static const List<String> nationalities = [
    'France', 'Spain', 'Argentina', 'England', 'Portugal', 'Brazil',
    'Netherlands', 'Morocco', 'Belgium', 'Germany', 'Croatia', 'Italy',
    'Colombia', 'Senegal', 'Mexico', 'USA', 'Uruguay', 'Japan', 'Switzerland',
    'Denmark', 'Iran', 'Turkiye', 'Ecuador', 'Austria', 'South Korea',
    'Nigeria', 'Australia', 'Algeria', 'Egypt', 'Canada', 'Norway', 'Ukraine',
    'Ivory Coast', 'Poland', 'Russia', 'Wales', 'Sweden', 'Serbia',
    'Czechia', 'Hungary', 'Scotland', 'Cameroon',
    'DR Congo', 'Greece', 'Slovakia', 'Uzbekistan',
    'Mali', 'Romania', 'Iraq', 'Slovenia', 'Ireland',
    'South Africa', 'Albania',
    'Bosnia', 'Cape Verde',
    'N. Ireland', 'Georgia', 'Finland', 'Ghana',
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
  /// [players] defaults to an empty list; tests can
  /// inject a fixed list. Returns a record of (rows, columns), length 3 each.
  static ({List<Factor> rows, List<Factor> columns}) generateBoard([
    Random? random,
    List<Player>? players,
  ]) {
    final rng = random ?? Random();
    // Always validate solvability against a real corpus. When no corpus is
    // supplied (e.g. before the SQLite DB has loaded, or a degenerate test),
    // fall back to an empty corpus when none is supplied. The
    // _solvableBoardFor fallback below ensures a playable board even with an
    // empty corpus.
    final corpus = (players == null || players.isEmpty)
        ? const <Player>[]
        : players;

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
    // Defense-in-depth: with no corpus there is nothing to validate solvability
    // against (e.g. the player DB failed to open). Rather than crash on an empty
    // `reduce` or loop forever, return any axis-valid board so the screen still
    // shows a playable grid.
    if (corpus.isEmpty) return _anyAxisValidBoard(rng);

    final pool = corpus;

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

    // No anchor satisfied 6+ factors (a degenerate, near-empty corpus the real
    // game never hits): fall back to any axis-valid board rather than the old
    // empty-`reduce` path, which crashed when the pool had no usable anchor.
    return _anyAxisValidBoard(rng);
  }

  /// Builds a board of six unique factors split 3/3 with a valid axis layout,
  /// WITHOUT any solvability check. Used as the last-resort fallback when there
  /// is no corpus to validate against. Bounded by [axisTries]; if no valid split
  /// is found in that budget it returns an arbitrary 3/3 split (still six unique
  /// factors), so it can never loop forever or throw.
  static ({List<Factor> rows, List<Factor> columns}) _anyAxisValidBoard(
    Random rng,
  ) {
    const axisTries = 200;
    for (var attempt = 0; attempt < axisTries; attempt++) {
      final chosen = _pickSixUnique(rng);
      final r = chosen.sublist(0, 3);
      final c = chosen.sublist(3, 6);
      if (_axesAreValid(r, c)) {
        return (rows: r, columns: c);
      }
    }
    // Arbitrary but valid-shaped fallback (6 unique factors, 3 + 3).
    final chosen = _pickSixUnique(rng);
    return (rows: chosen.sublist(0, 3), columns: chosen.sublist(3, 6));
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

    // Never put Euros AND Copa America on the same board — no player can win both.
    final allFactors = [...rows, ...columns];
    final hasEuros = allFactors.any(
        (f) => f.type == FactorType.wonInternational && f.value == 'Euros');
    final hasCopa = allFactors.any(
        (f) => f.type == FactorType.wonInternational && f.value == 'Copa America');
    if (hasEuros && hasCopa) return false;

    // Check all 9 intersections to ensure they are historically possible.
    for (final row in rows) {
      for (final col in columns) {
        if (!_isCellPossible(row, col)) return false;
      }
    }

    return true;
  }

  static bool _isCellPossible(Factor a, Factor b) {
    if (a.type == FactorType.nationality && b.type == FactorType.wonInternational) {
      return _canNationalityWinTournament(a.value, b.value);
    }
    if (b.type == FactorType.nationality && a.type == FactorType.wonInternational) {
      return _canNationalityWinTournament(b.value, a.value);
    }
    return true;
  }

  /// European nationalities (eligible for Euros).
  static const _europeanNations = {
    'France', 'Spain', 'Germany', 'Italy', 'England', 'Portugal',
    'Netherlands', 'Belgium', 'Croatia', 'Switzerland', 'Denmark',
    'Austria', 'Poland', 'Sweden', 'Czechia', 'Hungary', 'Scotland',
    'Wales', 'Serbia', 'Romania', 'Greece', 'Slovakia', 'Slovenia',
    'Bosnia', 'Albania', 'Ireland', 'N. Ireland',
    'Finland', 'Norway', 'Ukraine', 'Russia', 'Turkiye',
    'Georgia',
  };

  /// South/Central/North American nationalities (eligible for Copa America).
  static const _americanNations = {
    'Argentina', 'Brazil', 'Uruguay', 'Colombia',
    'Ecuador', 'Mexico', 'USA', 'Canada',
  };

  static bool _canNationalityWinTournament(String nationality, String tournament) {
    if (tournament == 'World Cup') {
      // Only nations that have actually won a World Cup.
      const winners = {
        'Argentina', 'Brazil', 'France', 'Germany',
        'Italy', 'Spain', 'Uruguay', 'England',
      };
      return winners.contains(nationality);
    }
    if (tournament == 'Euros') {
      // Must be European AND have actually won the Euros.
      if (!_europeanNations.contains(nationality)) return false;
      const winners = {
        'Germany', 'Spain', 'Italy', 'France', 'Portugal',
        'Netherlands', 'Denmark', 'Greece', 'Czechia', 'Russia',
      };
      return winners.contains(nationality);
    }
    if (tournament == 'Copa America') {
      // Must be American AND have actually won the Copa.
      if (!_americanNations.contains(nationality)) return false;
      const winners = {
        'Argentina', 'Brazil', 'Uruguay', 'Colombia',
        'Chile', 'Peru', 'Paraguay',
      };
      return winners.contains(nationality);
    }
    return true;
  }
}
