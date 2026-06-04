import 'package:http/http.dart' as http;

import '../game/xox/factor.dart';
import 'player.dart';
import 'player_attributes.dart';
import 'player_repository.dart';
import 'transfermarkt_service.dart';

/// [PlayerRepository] backed by a self-hosted **Transfermarkt API**.
///
/// Two layers:
/// 1. **Local cache** ([PlayerAttributes]) — players already fetched from
///    Transfermarkt, used for instant results and to guarantee board
///    solvability offline.
/// 2. **Transfermarkt** ([TransfermarktService]) — live search & validation
///    covering every footballer with a Transfermarkt profile, including
///    nationality, clubs and trophies (league titles + international wins).
///
/// Results from both layers are merged and de-duplicated. "Block at search":
/// every returned player satisfies BOTH cell factors.
class TransfermarktRepository implements PlayerRepository {
  TransfermarktRepository({http.Client? client, TransfermarktService? service})
      : _tm = service ?? TransfermarktService(client: client);

  final TransfermarktService _tm;

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

    final merged = <Player>[];
    final seenIds = <String>{};

    // ── Layer 1: local cache (instant) ──
    for (final p in _searchCache(trimmed)) {
      if (excludeIds.contains(p.id)) continue;
      if (rowFactor.matches(p) && columnFactor.matches(p)) {
        if (seenIds.add(p.id)) merged.add(p);
      }
    }

    // ── Layer 2: live Transfermarkt ──
    SearchStatus status = SearchStatus.ok;
    try {
      final live = await _tm.searchAndValidate(
        query: trimmed,
        rowFactor: rowFactor,
        columnFactor: columnFactor,
        excludeIds: excludeIds,
      );
      for (final p in live) {
        final nameKey = p.name.toLowerCase();
        final dup = merged.any((e) => e.name.toLowerCase() == nameKey);
        if (!dup && seenIds.add(p.id)) merged.add(p);
      }
    } catch (_) {
      // Transfermarkt unavailable — fall back to whatever the cache returned.
      status = merged.isEmpty ? SearchStatus.error : SearchStatus.ok;
    }

    return SearchResult(
      status: status,
      players: merged,
      message: merged.isEmpty
          ? (status == SearchStatus.error
              ? 'Could not reach the player service. Check the connection and try again.'
              : 'No player found matching both categories. Try another name.')
          : null,
    );
  }

  List<Player> _searchCache(String query) {
    final q = query.toLowerCase();
    return PlayerAttributes.all
        .where((p) => p.name.toLowerCase().contains(q))
        .toList();
  }
}

/// Backwards-compatible alias. The repository is now Transfermarkt-backed; the
/// old name is retained so existing call sites keep working.
typedef ApiFootballRepository = TransfermarktRepository;
