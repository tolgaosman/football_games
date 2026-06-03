import 'player.dart';

/// A curated, locally-maintained attribute table for factor validation.
///
/// Free football APIs cannot reliably answer "which leagues did this player
/// appear in / which titles did they win" for arbitrary past & present players
/// within their request quotas. So the API is used for *search* (finding real
/// players by name, including retired ones) while this table provides the
/// authoritative attributes used to validate a candidate against the two cell
/// factors.
///
/// To extend coverage, add more entries below — keys are matched
/// case-insensitively against the player's display name. League / title names
/// must match the canonical strings in `FactorPool`.
class PlayerAttributes {
  PlayerAttributes._();

  /// Canonical league names (must match `FactorPool.leagues`).
  static const _epl = 'Premier League';
  static const _ligue1 = 'Ligue 1';
  static const _bundesliga = 'Bundesliga';
  static const _serieA = 'Serie A';
  static const _laLiga = 'La Liga';
  static const _superLig = 'Trendyol Süper Lig';

  /// International tournaments (must match `FactorPool.internationalTournaments`).
  static const _worldCup = 'World Cup';
  static const _euros = 'Euros';
  static const _copa = 'Copa America';

  /// The attribute records, keyed by lowercase player name.
  static final Map<String, Player> _byName = _buildIndex([
    Player(
      id: 'messi',
      name: 'Lionel Messi',
      nationality: 'Argentina',
      leaguesPlayed: {_laLiga, _ligue1},
      leagueTitles: {_laLiga, _ligue1},
      internationalTitles: {_worldCup, _copa},
      teams: {'Barcelona', 'PSG'},
    ),
    Player(
      id: 'ronaldo',
      name: 'Cristiano Ronaldo',
      nationality: 'Portugal',
      leaguesPlayed: {_epl, _laLiga, _serieA},
      leagueTitles: {_epl, _laLiga, _serieA},
      internationalTitles: {_euros},
      teams: {'Manchester United', 'Real Madrid', 'Juventus'},
    ),
    Player(
      id: 'benzema',
      name: 'Karim Benzema',
      nationality: 'France',
      leaguesPlayed: {_ligue1, _laLiga},
      leagueTitles: {_ligue1, _laLiga},
      internationalTitles: {},
      teams: {'Lyon', 'Real Madrid'},
    ),
    Player(
      id: 'kante',
      name: "N'Golo Kanté",
      nationality: 'France',
      leaguesPlayed: {_ligue1, _epl},
      leagueTitles: {_epl},
      internationalTitles: {_worldCup},
      teams: {'Chelsea'},
    ),
    Player(
      id: 'mbappe',
      name: 'Kylian Mbappé',
      nationality: 'France',
      leaguesPlayed: {_ligue1, _laLiga},
      leagueTitles: {_ligue1, _laLiga},
      internationalTitles: {_worldCup},
      teams: {'PSG', 'Marseille', 'Real Madrid'},
    ),
    Player(
      id: 'griezmann',
      name: 'Antoine Griezmann',
      nationality: 'France',
      leaguesPlayed: {_laLiga},
      leagueTitles: {_laLiga},
      internationalTitles: {_worldCup},
      teams: {'Atletico Madrid', 'Barcelona'},
    ),
    Player(
      id: 'pogba',
      name: 'Paul Pogba',
      nationality: 'France',
      leaguesPlayed: {_epl, _serieA},
      leagueTitles: {_serieA},
      internationalTitles: {_worldCup},
      teams: {'Manchester United', 'Juventus'},
    ),
    Player(
      id: 'kroos',
      name: 'Toni Kroos',
      nationality: 'Germany',
      leaguesPlayed: {_bundesliga, _laLiga},
      leagueTitles: {_bundesliga, _laLiga},
      internationalTitles: {_worldCup},
      teams: {'Bayern Munich', 'Real Madrid'},
    ),
    Player(
      id: 'mueller',
      name: 'Thomas Müller',
      nationality: 'Germany',
      leaguesPlayed: {_bundesliga},
      leagueTitles: {_bundesliga},
      internationalTitles: {_worldCup},
      teams: {'Bayern Munich'},
    ),
    Player(
      id: 'modric',
      name: 'Luka Modrić',
      nationality: 'Croatia',
      leaguesPlayed: {_epl, _laLiga},
      leagueTitles: {_laLiga},
      internationalTitles: {},
      teams: {'Real Madrid'},
    ),
    Player(
      id: 'salah',
      name: 'Mohamed Salah',
      nationality: 'Egypt',
      leaguesPlayed: {_epl, _serieA, _laLiga},
      leagueTitles: {_epl},
      internationalTitles: {},
      teams: {'Liverpool', 'Chelsea'},
    ),
    Player(
      id: 'debruyne',
      name: 'Kevin De Bruyne',
      nationality: 'Belgium',
      leaguesPlayed: {_epl, _bundesliga},
      leagueTitles: {_epl},
      internationalTitles: {},
      teams: {'Manchester City', 'Chelsea'},
    ),
    Player(
      id: 'haaland',
      name: 'Erling Haaland',
      nationality: 'Norway',
      leaguesPlayed: {_bundesliga, _epl},
      leagueTitles: {_epl},
      internationalTitles: {},
      teams: {'Borussia Dortmund', 'Manchester City'},
    ),
    Player(
      id: 'lewandowski',
      name: 'Robert Lewandowski',
      nationality: 'Poland',
      leaguesPlayed: {_bundesliga, _laLiga},
      leagueTitles: {_bundesliga, _laLiga},
      internationalTitles: {},
      teams: {'Borussia Dortmund', 'Bayern Munich', 'Barcelona'},
    ),
    Player(
      id: 'neymar',
      name: 'Neymar',
      nationality: 'Brazil',
      leaguesPlayed: {_laLiga, _ligue1},
      leagueTitles: {_laLiga, _ligue1},
      internationalTitles: {},
      teams: {'Barcelona', 'PSG'},
    ),
    Player(
      id: 'vinicius',
      name: 'Vinícius Júnior',
      nationality: 'Brazil',
      leaguesPlayed: {_laLiga},
      leagueTitles: {_laLiga},
      internationalTitles: {},
      teams: {'Real Madrid'},
    ),
    Player(
      id: 'icardi',
      name: 'Mauro Icardi',
      nationality: 'Argentina',
      leaguesPlayed: {_serieA, _ligue1, _superLig},
      leagueTitles: {_ligue1, _superLig},
      internationalTitles: {},
      teams: {'Inter Milan', 'PSG', 'Galatasaray'},
    ),
    Player(
      id: 'dzeko',
      name: 'Edin Džeko',
      nationality: 'Bosnia',
      leaguesPlayed: {_bundesliga, _epl, _serieA, _superLig},
      leagueTitles: {_bundesliga, _epl},
      internationalTitles: {},
      teams: {'Manchester City', 'Inter Milan', 'Fenerbahce'},
    ),
    Player(
      id: 'drogba',
      name: 'Didier Drogba',
      nationality: 'Ivory Coast',
      leaguesPlayed: {_ligue1, _epl, _superLig},
      leagueTitles: {_epl, _superLig},
      internationalTitles: {},
      teams: {'Marseille', 'Chelsea', 'Galatasaray'},
    ),
    Player(
      id: 'sneijder',
      name: 'Wesley Sneijder',
      nationality: 'Netherlands',
      leaguesPlayed: {_laLiga, _serieA, _superLig},
      leagueTitles: {_serieA, _superLig},
      internationalTitles: {},
      teams: {'Real Madrid', 'Inter Milan', 'Galatasaray'},
    ),
    Player(
      id: 'falcao',
      name: 'Radamel Falcao',
      nationality: 'Colombia',
      leaguesPlayed: {_ligue1, _epl, _laLiga, _superLig},
      leagueTitles: {_ligue1, _superLig},
      internationalTitles: {},
      teams: {'Atletico Madrid', 'Manchester United', 'Galatasaray'},
    ),
    Player(
      id: 'cavani',
      name: 'Edinson Cavani',
      nationality: 'Uruguay',
      leaguesPlayed: {_serieA, _ligue1, _epl, _laLiga},
      leagueTitles: {_ligue1},
      internationalTitles: {},
      teams: {'Napoli', 'PSG', 'Manchester United'},
    ),
    Player(
      id: 'tevez',
      name: 'Carlos Tevez',
      nationality: 'Argentina',
      leaguesPlayed: {_epl, _serieA},
      leagueTitles: {_epl, _serieA},
      internationalTitles: {},
      teams: {'Manchester United', 'Manchester City', 'Juventus'},
    ),
    Player(
      id: 'ibrahimovic',
      name: 'Zlatan Ibrahimović',
      nationality: 'Sweden',
      leaguesPlayed: {_serieA, _laLiga, _ligue1, _epl},
      leagueTitles: {_serieA, _ligue1},
      internationalTitles: {},
      teams: {'Juventus', 'Inter Milan', 'Barcelona', 'AC Milan', 'PSG', 'Manchester United'},
    ),
    Player(
      id: 'hamsik',
      name: 'Marek Hamšík',
      nationality: 'Slovakia',
      leaguesPlayed: {_serieA},
      leagueTitles: {},
      internationalTitles: {},
      teams: {'Napoli'},
    ),
    Player(
      id: 'hagi',
      name: 'Gheorghe Hagi',
      nationality: 'Romania',
      leaguesPlayed: {_laLiga, _serieA, _superLig},
      leagueTitles: {_superLig},
      internationalTitles: {},
      teams: {'Real Madrid', 'Barcelona', 'Galatasaray'},
    ),
    Player(
      id: 'elnenny',
      name: 'Mohamed Elneny',
      nationality: 'Egypt',
      leaguesPlayed: {_superLig, _epl},
      leagueTitles: {_epl},
      internationalTitles: {},
      teams: {'Besiktas', 'Arsenal'},
    ),
    Player(
      id: 'kaka',
      name: 'Kaká',
      nationality: 'Brazil',
      leaguesPlayed: {_serieA, _laLiga},
      leagueTitles: {_serieA},
      internationalTitles: {_worldCup},
      teams: {'AC Milan', 'Real Madrid'},
    ),
    Player(
      id: 'pirlo',
      name: 'Andrea Pirlo',
      nationality: 'Italy',
      leaguesPlayed: {_serieA},
      leagueTitles: {_serieA},
      internationalTitles: {_worldCup},
      teams: {'AC Milan', 'Inter Milan', 'Juventus'},
    ),
    Player(
      id: 'xavi',
      name: 'Xavi Hernández',
      nationality: 'Spain',
      leaguesPlayed: {_laLiga},
      leagueTitles: {_laLiga},
      internationalTitles: {_worldCup, _euros},
      teams: {'Barcelona'},
    ),
    Player(
      id: 'iniesta',
      name: 'Andrés Iniesta',
      nationality: 'Spain',
      leaguesPlayed: {_laLiga},
      leagueTitles: {_laLiga},
      internationalTitles: {_worldCup, _euros},
      teams: {'Barcelona'},
    ),
    Player(
      id: 'ramos',
      name: 'Sergio Ramos',
      nationality: 'Spain',
      leaguesPlayed: {_laLiga, _ligue1},
      leagueTitles: {_laLiga},
      internationalTitles: {_worldCup, _euros},
      teams: {'Real Madrid', 'PSG'},
    ),
  ]);

  static Map<String, Player> _buildIndex(List<Player> players) {
    return {for (final p in players) p.name.toLowerCase(): p};
  }

  /// Returns curated attributes for a player [name], or null if unknown.
  ///
  /// Matching is case-insensitive and tolerant of partial matches so that an
  /// API result like "Lionel Andrés Messi" still resolves to "Lionel Messi".
  static Player? lookup(String name) {
    final key = name.toLowerCase().trim();
    final exact = _byName[key];
    if (exact != null) return exact;

    // Fall back to a loose contains-match in either direction.
    for (final entry in _byName.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return entry.value;
      }
    }
    return null;
  }

  /// All curated players (used as the offline search corpus when no API key
  /// is configured).
  static List<Player> get all => _byName.values.toList(growable: false);
}
