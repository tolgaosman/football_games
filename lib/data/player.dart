/// A football player candidate used by the XOX game.
///
/// Combines identity fields (often sourced from the API-Football search) with
/// the attributes needed for factor validation. League / title / team
/// attributes come from the local [PlayerAttributes] map; nationality may come
/// from the API response or the local fallback.
class Player {
  const Player({
    required this.id,
    required this.name,
    required this.nationality,
    this.photoUrl,
    this.leaguesPlayed = const {},
    this.leagueTitles = const {},
    this.internationalTitles = const {},
    this.teams = const {},
    this.wikipediaCategories = const {},
  });

  /// Stable id (API-Football player id when available, else a local slug).
  final String id;

  final String name;

  /// Country name, matched against nationality factors (e.g. "France").
  final String nationality;

  final String? photoUrl;

  /// Canonical league names the player has appeared in.
  /// e.g. {"Premier League", "La Liga"}.
  final Set<String> leaguesPlayed;

  /// Domestic league titles the player has won, by league name.
  /// e.g. {"Premier League", "Ligue 1"}.
  final Set<String> leagueTitles;

  /// International tournaments won. e.g. {"World Cup", "Euros"}.
  final Set<String> internationalTitles;

  /// Notable clubs the player has represented. e.g. {"Real Madrid"}.
  final Set<String> teams;

  /// Categories fetched dynamically from Wikipedia for validation.
  final Set<String> wikipediaCategories;

  Player copyWith({
    String? nationality,
    String? photoUrl,
    Set<String>? leaguesPlayed,
    Set<String>? leagueTitles,
    Set<String>? internationalTitles,
    Set<String>? teams,
    Set<String>? wikipediaCategories,
  }) {
    return Player(
      id: id,
      name: name,
      nationality: nationality ?? this.nationality,
      photoUrl: photoUrl ?? this.photoUrl,
      leaguesPlayed: leaguesPlayed ?? this.leaguesPlayed,
      leagueTitles: leagueTitles ?? this.leagueTitles,
      internationalTitles: internationalTitles ?? this.internationalTitles,
      teams: teams ?? this.teams,
      wikipediaCategories: wikipediaCategories ?? this.wikipediaCategories,
    );
  }
}
