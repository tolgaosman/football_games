import '../game/xox/factor.dart';
import 'player_attributes.dart';
import 'player.dart';
import 'player_repository.dart';

/// A fully local [PlayerRepository] backed by the hardcoded [PlayerAttributes].
///
/// There is no network layer: searches run entirely against the offline pool,
/// so the game works without any external service. "Block at search": every
/// returned player satisfies BOTH cell factors, so anything the user can tap is
/// a legal answer.
class FootballerRepository implements PlayerRepository {
  const FootballerRepository();

  @override
  Future<SearchResult> searchValid({
    required String query,
    required Factor rowFactor,
    required Factor columnFactor,
    Set<String> excludeIds = const {},
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) {
      return const SearchResult(
        status: SearchStatus.ok,
        players: [],
        message: 'Type at least 3 letters to search.',
      );
    }

    final q = trimmed.toLowerCase();
    final matches = <Player>[];
    final seenIds = <String>{};

    for (final p in PlayerAttributes.all) {
      if (!p.name.toLowerCase().contains(q)) continue;
      if (excludeIds.contains(p.id)) continue;
      if (!rowFactor.matches(p) || !columnFactor.matches(p)) continue;
      if (seenIds.add(p.id)) matches.add(p);
    }

    return SearchResult(
      status: SearchStatus.ok,
      players: matches,
      message: matches.isEmpty
          ? 'No player found matching both categories. Try another name.'
          : null,
    );
  }
}
