import 'dart:math';

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

  /// ~20 major clubs drawn from the six leagues above.
  static const List<String> teams = [
    'Arsenal',
    'Manchester City',
    'Liverpool',
    'Chelsea',
    'Manchester United',
    'Real Madrid',
    'Barcelona',
    'Atletico Madrid',
    'Bayern Munich',
    'Borussia Dortmund',
    'Juventus',
    'AC Milan',
    'Inter Milan',
    'Napoli',
    'PSG',
    'Marseille',
    'Lyon',
    'Galatasaray',
    'Fenerbahce',
    'Besiktas',
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

  /// Picks 3 row + 3 column factors, all six guaranteed unique, satisfying the
  /// axis-exclusivity rules (see [_axesAreValid]).
  ///
  /// Returns a record of (rows, columns), each a list of length 3.
  static ({List<Factor> rows, List<Factor> columns}) generateBoard([
    Random? random,
  ]) {
    final rng = random ?? Random();

    // Reject-sample whole draws until the row/column split obeys the rules.
    // With a 100+ factor pool a valid draw is found almost immediately; the cap
    // guards against pathological cases.
    const maxAttempts = 200;
    List<Factor>? rows;
    List<Factor>? columns;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final chosen = _pickSixUnique(rng);
      final r = chosen.sublist(0, 3);
      final c = chosen.sublist(3, 6);
      if (_axesAreValid(r, c)) {
        rows = r;
        columns = c;
        break;
      }
    }

    // Fallback (should never trigger): use the last valid-or-not draw.
    if (rows == null || columns == null) {
      final chosen = _pickSixUnique(rng);
      rows = chosen.sublist(0, 3);
      columns = chosen.sublist(3, 6);
    }

    return (rows: rows, columns: columns);
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
