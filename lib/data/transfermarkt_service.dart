import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../game/xox/factor.dart';
import '../game/xox/factor_pool.dart';
import 'player.dart';

/// Dynamic player search & validation powered by a self-hosted
/// **Transfermarkt API** (https://github.com/felipeall/transfermarkt-api).
///
/// Search finds real footballers (incl. retired) by name; each candidate is
/// then enriched from three endpoints and mapped to the game's canonical
/// factors:
///
/// - `profile`      → nationality (`citizenship` list)
/// - `transfers`    → clubs played for (`Player.teams`)
/// - `achievements` → league titles (`Player.leagueTitles`) and international
///   tournament wins (`Player.internationalTitles`)
///
/// Unlike the previous Wikipedia source, Transfermarkt exposes domestic
/// league-title data, so the `wonLeague` factor is validatable here.
class TransfermarktService {
  TransfermarktService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.transfermarktBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  /// How many search hits to enrich per query. Each enriched candidate costs
  /// three HTTP calls (profile + transfers + achievements), so this is capped.
  static const _maxCandidates = 8;

  static const _timeout = Duration(seconds: 8);

  // ─── Public API ───────────────────────────────────────────────────────

  /// Searches Transfermarkt for footballers matching [query], enriches the top
  /// candidates, and returns those satisfying BOTH factors (excluding
  /// [excludeIds]).
  Future<List<Player>> searchAndValidate({
    required String query,
    required Factor rowFactor,
    required Factor columnFactor,
    Set<String> excludeIds = const {},
  }) async {
    final hits = await _search(query);
    if (hits.isEmpty) return [];

    final result = <Player>[];
    final seen = <String>{};
    for (final hit in hits.take(_maxCandidates)) {
      // Compare against the public player id form (matches Player.id below), so
      // already-used players are skipped before the expensive enrichment calls.
      if (excludeIds.contains(_playerId(hit.id))) continue;
      final player = await _enrich(hit);
      if (player == null) continue;
      if (rowFactor.matches(player) && columnFactor.matches(player)) {
        if (seen.add(player.id)) result.add(player);
      }
    }
    return result;
  }

  /// Fetches and fully enriches a single player by Transfermarkt id. Exposed so
  /// the local cache builder can reuse the same mapping logic.
  Future<Player?> fetchPlayer(String id, String name) =>
      _enrich(_SearchHit(id: id, name: name));

  // ─── Search ─────────────────────────────────────────────────────────────

  Future<List<_SearchHit>> _search(String query) async {
    final uri = Uri.parse('$_baseUrl/players/search/${Uri.encodeComponent(query)}');
    final body = await _getJson(uri);
    if (body == null) return [];
    final results = (body['results'] as List?) ?? const [];
    return results
        .map((r) => _SearchHit(
              id: (r as Map<String, dynamic>)['id']?.toString() ?? '',
              name: r['name']?.toString() ?? '',
            ))
        .where((h) => h.id.isNotEmpty && h.name.isNotEmpty)
        .toList();
  }

  // ─── Enrichment ───────────────────────────────────────────────────────

  /// Public, stable player id derived from the Transfermarkt id.
  static String _playerId(String transfermarktId) => 'tm-$transfermarktId';

  Future<Player?> _enrich(_SearchHit hit) async {
    final profile = await _getJson(Uri.parse('$_baseUrl/players/${hit.id}/profile'));
    if (profile == null) return null;

    final transfers =
        await _getJson(Uri.parse('$_baseUrl/players/${hit.id}/transfers'));
    final achievements =
        await _getJson(Uri.parse('$_baseUrl/players/${hit.id}/achievements'));

    final nationality = _mapNationality(profile);
    final teams = _mapTeams(transfers);
    final titles = _mapAchievements(achievements);

    return Player(
      id: _playerId(hit.id),
      name: hit.name,
      nationality: nationality,
      photoUrl: profile['imageUrl']?.toString(),
      leaguesPlayed: _leaguesFromTeams(teams),
      leagueTitles: titles.leagues,
      internationalTitles: titles.international,
      teams: teams,
    );
  }

  /// Picks the first `citizenship` entry that maps to a known FactorPool
  /// nationality (the list is ordered with the sporting nationality first).
  String _mapNationality(Map<String, dynamic> profile) {
    final citizenship = (profile['citizenship'] as List?) ?? const [];
    for (final raw in citizenship) {
      final mapped = _canonicalNationality(raw.toString());
      if (mapped != null) return mapped;
    }
    return citizenship.isNotEmpty ? citizenship.first.toString() : '';
  }

  /// Union of every club a player transferred from/to, mapped to canonical
  /// FactorPool team names.
  Set<String> _mapTeams(Map<String, dynamic>? transfers) {
    final teams = <String>{};
    if (transfers == null) return teams;
    for (final t in (transfers['transfers'] as List?) ?? const []) {
      final map = t as Map<String, dynamic>;
      for (final side in ['clubFrom', 'clubTo']) {
        final name = (map[side] as Map<String, dynamic>?)?['name']?.toString();
        if (name == null) continue;
        final canonical = _canonicalTeam(name);
        if (canonical != null) teams.add(canonical);
      }
    }
    return teams;
  }

  /// Parses the achievements feed into won-league and won-international sets.
  _Titles _mapAchievements(Map<String, dynamic>? achievements) {
    final leagues = <String>{};
    final international = <String>{};
    if (achievements == null) return _Titles(leagues, international);

    for (final a in (achievements['achievements'] as List?) ?? const []) {
      final map = a as Map<String, dynamic>;
      final title = (map['title']?.toString() ?? '').toLowerCase();

      // International tournaments are identified by the achievement title.
      if (title.contains('world cup')) international.add('World Cup');
      if (title.contains('european championship') ||
          (title.contains('euro') && !title.contains('europa'))) {
        international.add('Euros');
      }
      if (title.contains('copa américa') || title.contains('copa america')) {
        international.add('Copa America');
      }

      // Domestic league titles: the title (and the per-season competition name)
      // carries the league, e.g. "La Liga winner", "Bundesliga champion".
      _matchLeagueTitle(title, leagues);
      for (final d in (map['details'] as List?) ?? const []) {
        final comp = ((d as Map<String, dynamic>)['competition']
                as Map<String, dynamic>?)?['name']
            ?.toString()
            .toLowerCase();
        if (comp != null) _matchLeagueTitle(comp, leagues);
      }
    }
    return _Titles(leagues, international);
  }

  void _matchLeagueTitle(String text, Set<String> out) {
    for (final entry in _leagueTitlePatterns.entries) {
      if (text.contains(entry.key)) out.add(entry.value);
    }
  }

  /// A player who won a domestic league necessarily played in it; treat the
  /// won-leagues as a baseline for leaguesPlayed too. (Played-only coverage is
  /// further widened by the team→league inference below.)
  Set<String> _leaguesFromTeams(Set<String> teams) {
    final leagues = <String>{};
    for (final team in teams) {
      final league = _teamLeague[team];
      if (league != null) leagues.add(league);
    }
    return leagues;
  }

  // ─── HTTP helper ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> _getJson(Uri uri) async {
    try {
      final res = await _client.get(uri).timeout(_timeout);
      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(res.body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  // ─── Canonical-name mapping ─────────────────────────────────────────────

  String? _canonicalNationality(String raw) => _nationalityMap[raw.trim()];

  String? _canonicalTeam(String raw) {
    final lower = raw.toLowerCase();
    for (final entry in _teamMap.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return null;
  }

  /// Lowercased Transfermarkt club-name substrings → canonical FactorPool team.
  static final Map<String, String> _teamMap = {
    for (final team in FactorPool.teams) ..._teamAliases(team),
  };

  /// Canonical team → its league (for inferring leaguesPlayed from clubs).
  static const Map<String, String> _teamLeague = {
    'Arsenal': 'Premier League',
    'Aston Villa': 'Premier League',
    'Brighton': 'Premier League',
    'Chelsea': 'Premier League',
    'Crystal Palace': 'Premier League',
    'Liverpool': 'Premier League',
    'Manchester City': 'Premier League',
    'Manchester United': 'Premier League',
    'Newcastle United': 'Premier League',
    'Nottingham Forest': 'Premier League',
    'Tottenham Hotspur': 'Premier League',
    'West Ham United': 'Premier League',
    'Real Madrid': 'La Liga',
    'Barcelona': 'La Liga',
    'Atletico Madrid': 'La Liga',
    'Athletic Bilbao': 'La Liga',
    'Real Betis': 'La Liga',
    'Sevilla': 'La Liga',
    'Villarreal': 'La Liga',
    'Bayern Munich': 'Bundesliga',
    'Borussia Dortmund': 'Bundesliga',
    'Bayer Leverkusen': 'Bundesliga',
    'Eintracht Frankfurt': 'Bundesliga',
    'RB Leipzig': 'Bundesliga',
    'VfL Wolfsburg': 'Bundesliga',
    'AC Milan': 'Serie A',
    'Inter Milan': 'Serie A',
    'Juventus': 'Serie A',
    'Napoli': 'Serie A',
    'Atalanta': 'Serie A',
    'Roma': 'Serie A',
    'Lazio': 'Serie A',
    'Fiorentina': 'Serie A',
    'PSG': 'Ligue 1',
    'Lyon': 'Ligue 1',
    'Lille': 'Ligue 1',
    'Marseille': 'Ligue 1',
    'Monaco': 'Ligue 1',
    'Galatasaray': 'Trendyol Süper Lig',
    'Fenerbahce': 'Trendyol Süper Lig',
    'Besiktas': 'Trendyol Süper Lig',
    'Trabzonspor': 'Trendyol Süper Lig',
    'Başakşehir': 'Trendyol Süper Lig',
  };

  static Map<String, String> _teamAliases(String team) {
    const aliases = <String, List<String>>{
      'Arsenal': ['arsenal'],
      'Aston Villa': ['aston villa'],
      'Brighton': ['brighton'],
      'Chelsea': ['chelsea'],
      'Crystal Palace': ['crystal palace'],
      'Liverpool': ['liverpool'],
      'Manchester City': ['manchester city', 'man city'],
      'Manchester United': ['manchester united', 'man utd', 'man united'],
      'Newcastle United': ['newcastle'],
      'Nottingham Forest': ['nottingham forest'],
      'Tottenham Hotspur': ['tottenham', 'spurs'],
      'West Ham United': ['west ham'],
      'Real Madrid': ['real madrid'],
      'Barcelona': ['barcelona', 'fc barcelona'],
      'Atletico Madrid': ['atlético de madrid', 'atletico de madrid', 'atlético madrid', 'atletico madrid'],
      'Athletic Bilbao': ['athletic bilbao', 'athletic club'],
      'Real Betis': ['real betis', 'betis'],
      'Sevilla': ['sevilla'],
      'Villarreal': ['villarreal'],
      'Bayern Munich': ['bayern munich', 'bayern münchen', 'fc bayern'],
      'Borussia Dortmund': ['borussia dortmund', 'bv borussia 09 dortmund'],
      'Bayer Leverkusen': ['bayer 04 leverkusen', 'bayer leverkusen', 'leverkusen'],
      'Eintracht Frankfurt': ['eintracht frankfurt'],
      'RB Leipzig': ['rb leipzig', 'rasenballsport leipzig'],
      'VfL Wolfsburg': ['vfl wolfsburg', 'wolfsburg'],
      'AC Milan': ['ac milan', 'milan'],
      'Inter Milan': ['inter milan', 'internazionale', 'inter'],
      'Juventus': ['juventus'],
      'Napoli': ['napoli', 'ssc napoli'],
      'Atalanta': ['atalanta'],
      'Roma': ['as roma', 'roma'],
      'Lazio': ['lazio'],
      'Fiorentina': ['fiorentina'],
      'PSG': ['paris saint-germain', 'paris sg'],
      'Lyon': ['olympique lyon', 'olympique lyonnais'],
      'Lille': ['lille', 'losc'],
      'Marseille': ['olympique marseille', 'marseille'],
      'Monaco': ['as monaco', 'monaco'],
      'Galatasaray': ['galatasaray'],
      'Fenerbahce': ['fenerbahçe', 'fenerbahce'],
      'Besiktas': ['beşiktaş', 'besiktas'],
      'Trabzonspor': ['trabzonspor'],
      'Başakşehir': ['başakşehir', 'basaksehir', 'istanbul başakşehir'],
    };
    final mapped = aliases[team];
    if (mapped != null) return {for (final a in mapped) a: team};
    return {team.toLowerCase(): team};
  }

  /// Lowercased substrings in an achievement/competition title → won league.
  static const Map<String, String> _leagueTitlePatterns = {
    'premier league': 'Premier League',
    'la liga': 'La Liga',
    'laliga': 'La Liga',
    'serie a': 'Serie A',
    'bundesliga': 'Bundesliga',
    'ligue 1': 'Ligue 1',
    'süper lig': 'Trendyol Süper Lig',
    'super lig': 'Trendyol Süper Lig',
  };

  /// Transfermarkt citizenship label → canonical FactorPool nationality.
  /// Transfermarkt uses country names (e.g. "Türkiye", "Côte d'Ivoire").
  static const Map<String, String> _nationalityMap = {
    'France': 'France',
    'Spain': 'Spain',
    'Argentina': 'Argentina',
    'England': 'England',
    'Portugal': 'Portugal',
    'Brazil': 'Brazil',
    'Netherlands': 'Netherlands',
    'Morocco': 'Morocco',
    'Belgium': 'Belgium',
    'Germany': 'Germany',
    'Croatia': 'Croatia',
    'Italy': 'Italy',
    'Colombia': 'Colombia',
    'Senegal': 'Senegal',
    'Mexico': 'Mexico',
    'United States': 'USA',
    'Uruguay': 'Uruguay',
    'Japan': 'Japan',
    'Switzerland': 'Switzerland',
    'Denmark': 'Denmark',
    'Iran': 'Iran',
    'Türkiye': 'Turkiye',
    'Turkey': 'Turkiye',
    'Ecuador': 'Ecuador',
    'Austria': 'Austria',
    'Korea, South': 'South Korea',
    'South Korea': 'South Korea',
    'Nigeria': 'Nigeria',
    'Australia': 'Australia',
    'Algeria': 'Algeria',
    'Egypt': 'Egypt',
    'Canada': 'Canada',
    'Norway': 'Norway',
    'Ukraine': 'Ukraine',
    'Panama': 'Panama',
    "Cote d'Ivoire": 'Ivory Coast',
    "Côte d'Ivoire": 'Ivory Coast',
    'Ivory Coast': 'Ivory Coast',
    'Poland': 'Poland',
    'Russia': 'Russia',
    'Wales': 'Wales',
    'Sweden': 'Sweden',
    'Serbia': 'Serbia',
    'Paraguay': 'Paraguay',
    'Czech Republic': 'Czechia',
    'Czechia': 'Czechia',
    'Hungary': 'Hungary',
    'Scotland': 'Scotland',
    'Tunisia': 'Tunisia',
    'Cameroon': 'Cameroon',
    'DR Congo': 'DR Congo',
    'Congo DR': 'DR Congo',
    'Greece': 'Greece',
    'Slovakia': 'Slovakia',
    'Venezuela': 'Venezuela',
    'Uzbekistan': 'Uzbekistan',
    'Costa Rica': 'Costa Rica',
    'Mali': 'Mali',
    'Peru': 'Peru',
    'Chile': 'Chile',
    'Qatar': 'Qatar',
    'Romania': 'Romania',
    'Iraq': 'Iraq',
    'Slovenia': 'Slovenia',
    'Ireland': 'Ireland',
    'Republic of Ireland': 'Ireland',
    'South Africa': 'South Africa',
    'Saudi Arabia': 'Saudi Arabia',
    'Burkina Faso': 'Burkina Faso',
    'Jordan': 'Jordan',
    'Albania': 'Albania',
    'Bosnia-Herzegovina': 'Bosnia',
    'Bosnia and Herzegovina': 'Bosnia',
    'Honduras': 'Honduras',
    'North Macedonia': 'North Macedonia',
    'United Arab Emirates': 'UAE',
    'Cape Verde': 'Cape Verde',
    'Northern Ireland': 'N. Ireland',
    'Jamaica': 'Jamaica',
    'Georgia': 'Georgia',
    'Finland': 'Finland',
    'Ghana': 'Ghana',
    'Iceland': 'Iceland',
  };
}

/// A lightweight search hit before enrichment.
class _SearchHit {
  const _SearchHit({required this.id, required this.name});
  final String id;
  final String name;
}

/// Parsed trophy sets.
class _Titles {
  const _Titles(this.leagues, this.international);
  final Set<String> leagues;
  final Set<String> international;
}
