import '../game/xox/factor.dart';
import 'player.dart';

/// Outcome status of a player search.
enum SearchStatus {
  ok,

  /// No API key configured — running against the local corpus only.
  noApiKey,

  /// A network/parse error occurred while contacting the API.
  error,
}

/// The result of a validated player search.
///
/// [players] only ever contains candidates that satisfy BOTH cell factors
/// ("block at search"), so any returned player is a legal selection.
class SearchResult {
  const SearchResult({
    required this.status,
    this.players = const [],
    this.message,
  });

  final SearchStatus status;
  final List<Player> players;

  /// Optional human-readable message (e.g. error / no-key explanation).
  final String? message;

  bool get isEmpty => players.isEmpty;
}

/// Abstraction over the player data source.
///
/// Implementations are responsible for turning a free-text [query] into real
/// player candidates and then filtering them down to those that satisfy both
/// the [rowFactor] and [columnFactor]. Keeping this abstract lets the data
/// source be swapped (API, local JSON, hybrid) without touching the UI.
abstract class PlayerRepository {
  /// Searches for players matching [query] who satisfy both factors. Any player
  /// whose id is in [excludeIds] (already used this match) is filtered out.
  Future<SearchResult> searchValid({
    required String query,
    required Factor rowFactor,
    required Factor columnFactor,
    Set<String> excludeIds,
  });
}
