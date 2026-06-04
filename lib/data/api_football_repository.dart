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

    if (!AppConfig.hasApiKey) {
      // Offline fallback: search the curated corpus by name.
      final matches = _searchLocal(trimmed);
      final valid = await _filterAsync(matches, rowFactor, columnFactor, excludeIds);
      return SearchResult(
        status: SearchStatus.noApiKey,
        players: valid,
        message:
            'No API key set — searching offline sample players. Add API_FOOTBALL_KEY for full search.',
      );
    }

    try {
      final candidates = await _searchApi(trimmed);
      final valid = await _filterAsync(candidates, rowFactor, columnFactor, excludeIds);
      return SearchResult(status: SearchStatus.ok, players: valid);
    } catch (e) {
      // On any API failure, degrade to the local corpus rather than failing.
      final matches = _searchLocal(trimmed);
      final valid = await _filterAsync(matches, rowFactor, columnFactor, excludeIds);
      return SearchResult(
        status: SearchStatus.error,
        players: valid,
        message: 'API unavailable — showing offline results.',
      );
    }
  }

  /// Filters candidates down to those satisfying both factors.
  /// If a candidate is not in the local curated attributes, we fetch their Wikipedia categories
  /// to validate them dynamically, supporting any player of all time.
  Future<List<Player>> _filterAsync(
    List<Player> candidates,
    Factor rowFactor,
    Factor columnFactor,
    Set<String> excludeIds,
  ) async {
    final result = <Player>[];
    final seen = <String>{};
    final unknownCandidates = <Player>[];

    for (final candidate in candidates) {
      if (excludeIds.contains(candidate.id)) continue;
      
      final curated = PlayerAttributes.lookup(candidate.name);
      if (curated != null) {
        final enriched = curated.copyWith(
          nationality: candidate.nationality.isNotEmpty ? candidate.nationality : curated.nationality,
          photoUrl: candidate.photoUrl ?? curated.photoUrl,
        );
        if (rowFactor.matches(enriched) && columnFactor.matches(enriched)) {
          if (seen.add(enriched.id)) result.add(enriched);
        }
      } else {
        unknownCandidates.add(candidate);
      }
    }

    // Dynamic Wikipedia validation for un-curated players
    if (unknownCandidates.isNotEmpty) {
      try {
        final titles = unknownCandidates.map((c) => c.name).take(40).toList();
        final uri = Uri.parse(
            'https://en.wikipedia.org/w/api.php?action=query&prop=categories&titles=${titles.map(Uri.encodeComponent).join("|")}&redirects=1&cllimit=max&format=json');
        
        final response = await _client.get(uri).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          final pages = (body['query']?['pages'] as Map?)?.values ?? [];
          
          final categoryMap = <String, Set<String>>{};
          for (final page in pages) {
            final title = page['title']?.toString().toLowerCase() ?? '';
            final cats = (page['categories'] as List?)
                ?.map((c) => c['title'].toString())
                .toSet() ?? {};
            categoryMap[title] = cats;
          }
          
          for (final candidate in unknownCandidates) {
            Set<String>? cats;
            final lowerName = candidate.name.toLowerCase();
            // Match returned Wikipedia page titles against the candidate name.
            for (final entry in categoryMap.entries) {
              if (lowerName.contains(entry.key) || entry.key.contains(lowerName)) {
                cats = entry.value;
                break;
              }
            }
            
            if (cats != null && cats.isNotEmpty) {
               final enriched = candidate.copyWith(wikipediaCategories: cats);
               if (rowFactor.matches(enriched) && columnFactor.matches(enriched)) {
                  if (seen.add(enriched.id)) result.add(enriched);
               }
            }
          }
        }
      } catch (_) {
        // Fallback: if Wikipedia fails, we can't validate unknown players.
      }
    }

    return result;
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
