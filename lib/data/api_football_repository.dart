import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../game/xox/factor.dart';
import 'player.dart';
import 'player_attributes.dart';
import 'player_repository.dart';

/// [PlayerRepository] backed by API-Football for *search* and the local
/// [PlayerAttributes] table for *validation*.
///
/// Flow:
/// 1. Hit API-Football `players/profiles?search=` to find real players by name
///    (covers past & present footballers).
/// 2. Merge each candidate with curated local attributes (leagues, titles,
///    teams); nationality comes from the API with a local fallback.
/// 3. Keep only candidates satisfying BOTH the row and column factors.
///
/// When no API key is configured the repository transparently searches the
/// local curated corpus instead, so the UI still works end-to-end offline.
class ApiFootballRepository implements PlayerRepository {
  ApiFootballRepository({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<SearchResult> searchValid({
    required String query,
    required Factor rowFactor,
    required Factor columnFactor,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) {
      return const SearchResult(
        status: SearchStatus.ok,
        players: [],
        message: 'Type at least 3 letters to search.',
      );
    }

    if (!AppConfig.hasApiKey) {
      // Offline fallback: search the curated corpus by name.
      final matches = _searchLocal(trimmed);
      final valid = _filter(matches, rowFactor, columnFactor);
      return SearchResult(
        status: SearchStatus.noApiKey,
        players: valid,
        message:
            'No API key set — searching offline sample players. Add API_FOOTBALL_KEY for full search.',
      );
    }

    try {
      final candidates = await _searchApi(trimmed);
      final valid = _filter(candidates, rowFactor, columnFactor);
      return SearchResult(status: SearchStatus.ok, players: valid);
    } catch (e) {
      // On any API failure, degrade to the local corpus rather than failing.
      final matches = _searchLocal(trimmed);
      final valid = _filter(matches, rowFactor, columnFactor);
      return SearchResult(
        status: SearchStatus.error,
        players: valid,
        message: 'API unavailable — showing offline results.',
      );
    }
  }

  /// Filters candidates down to those satisfying both factors and merges in
  /// curated attributes so validation has data to work with.
  List<Player> _filter(
    List<Player> candidates,
    Factor rowFactor,
    Factor columnFactor,
  ) {
    final result = <Player>[];
    final seen = <String>{};
    for (final candidate in candidates) {
      final enriched = _enrich(candidate);
      if (rowFactor.matches(enriched) && columnFactor.matches(enriched)) {
        if (seen.add(enriched.id)) result.add(enriched);
      }
    }
    return result;
  }

  /// Merges API identity with curated attributes. The curated record wins for
  /// league/title/team data; nationality prefers the API value when present.
  Player _enrich(Player candidate) {
    final curated = PlayerAttributes.lookup(candidate.name);
    if (curated == null) return candidate;
    return curated.copyWith(
      nationality: candidate.nationality.isNotEmpty
          ? candidate.nationality
          : curated.nationality,
      photoUrl: candidate.photoUrl ?? curated.photoUrl,
    );
  }

  List<Player> _searchLocal(String query) {
    final q = query.toLowerCase();
    return PlayerAttributes.all
        .where((p) => p.name.toLowerCase().contains(q))
        .toList();
  }

  Future<List<Player>> _searchApi(String query) async {
    final uri = Uri.https(
      AppConfig.apiFootballHost,
      '/players/profiles',
      {'search': query},
    );

    final response = await _client.get(
      uri,
      headers: {'x-apisports-key': AppConfig.apiFootballKey},
    );

    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (body['response'] as List?) ?? const [];

    return list.map((raw) {
      final player = (raw as Map<String, dynamic>)['player']
              as Map<String, dynamic>? ??
          raw;
      final first = player['firstname']?.toString() ?? '';
      final last = player['lastname']?.toString() ?? '';
      final name = (player['name']?.toString().trim().isNotEmpty ?? false)
          ? player['name'].toString()
          : '$first $last'.trim();
      return Player(
        id: player['id']?.toString() ?? name,
        name: name,
        nationality: player['nationality']?.toString() ?? '',
        photoUrl: player['photo']?.toString(),
      );
    }).toList();
  }
}
