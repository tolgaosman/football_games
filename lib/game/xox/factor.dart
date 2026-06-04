import '../../data/player.dart';

/// The kind of constraint a [Factor] expresses.
enum FactorType {
  /// Player appeared in a given league.
  playedLeague,

  /// Player won a given domestic league title.
  wonLeague,

  /// Player won a given international tournament.
  wonInternational,

  /// Player represented a given club.
  team,

  /// Player holds a given nationality.
  nationality,
}

/// A single XOX axis constraint (a row or column "category").
///
/// Each factor carries the [label] shown in the header and a [value] used by
/// [matches] to test a candidate [Player]. Two factors are considered equal
/// when their type + value match, which the board generator uses to guarantee
/// all six headers are unique.
class Factor {
  const Factor({
    required this.type,
    required this.label,
    required this.value,
  });

  final FactorType type;

  /// Human-readable header text, e.g. "Played in Premier League".
  final String label;

  /// The canonical value tested against player attributes,
  /// e.g. "Premier League", "World Cup", "Real Madrid", "France".
  final String value;

  /// True when this factor constrains nationality. Two nationality factors on
  /// opposing axes would create impossible cells, so the board generator never
  /// places one on a row and another on a column.
  bool get isNationality => type == FactorType.nationality;

  /// True when this factor is an international tournament title. Like
  /// nationalities, two of these on opposing axes are mutually exclusive.
  bool get isInternational => type == FactorType.wonInternational;

  /// Returns true when [player] satisfies this constraint.
  bool matches(Player player) {
    if (player.wikipediaCategories.isNotEmpty && !isNationality) {
      // Use dynamic Wikipedia validation!
      // Categories look like "Category:Real Madrid CF players", "Category:Süper Lig players"
      final val = value.toLowerCase();
      // Adjust value for international tournaments
      String searchVal = val;
      if (type == FactorType.wonInternational) {
        if (val == 'world cup') searchVal = 'fifa world cup';
        if (val == 'euros') searchVal = 'uefa euro';
        if (val == 'copa america') searchVal = 'copa américa';
      }
      
      for (final cat in player.wikipediaCategories) {
        if (cat.toLowerCase().contains(searchVal)) {
          return true;
        }
      }
      // If we fall through and we have wikipedia categories, it means Wikipedia says they don't match.
      // But we can fallback to the local DB just in case Wikipedia is missing a category.
    }

    switch (type) {
      case FactorType.playedLeague:
        return player.leaguesPlayed.contains(value);
      case FactorType.wonLeague:
        return player.leagueTitles.contains(value);
      case FactorType.wonInternational:
        return player.internationalTitles.contains(value);
      case FactorType.team:
        return player.teams.contains(value);
      case FactorType.nationality:
        return player.nationality == value;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Factor && other.type == type && other.value == value;

  @override
  int get hashCode => Object.hash(type, value);

  @override
  String toString() => 'Factor($type, $value)';
}
