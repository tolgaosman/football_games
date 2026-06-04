import 'player.dart';

/// A curated, local player cache for factor validation and board solvability.
///
/// Live player data comes from Transfermarkt ([TransfermarktService]), but the
/// XOX board generator needs a guaranteed-solvable set of players *offline* —
/// before any network call — so every generated cell has at least one real
/// answer. This table is that seed cache: a hand-verified corpus whose
/// attributes already match the canonical `FactorPool` names.
///
/// It doubles as instant offline search results. To widen coverage, add more
/// entries (or regenerate from Transfermarkt via the scratch tooling) — keys
/// are matched case-insensitively against the display name, and league / title
/// names MUST match the canonical strings in `FactorPool`.
class PlayerAttributes {
  PlayerAttributes._();

  // Constants removed because the array is empty

  /// The attribute records, keyed by lowercase player name.
  static final Map<String, Player> _byName = _buildIndex([]);

  static Map<String, Player> _buildIndex(List<Player> players) {
    return {for (final p in players) p.name.toLowerCase(): p};
  }

  /// Returns the cached attributes for [name] (case-insensitive), or null
  /// if not in the local corpus.
  static Player? lookup(String name) => _byName[name.toLowerCase()];

  /// All curated players (used as the offline search corpus when no API key
  /// is configured).
  static List<Player> get all => _byName.values.toList(growable: false);
}
