/// Canonical SQLite schema for the on-device player database.
///
/// Shared between the build-time generator ([scratch/build_db.dart]) and the
/// runtime opener ([PlayerDatabase]) so the table/column/index definitions can
/// never drift apart. Table strings (league / team / nationality / tournament)
/// MUST match the canonical names in `FactorPool` exactly — the generator reads
/// them straight from the player database, which already uses those names.
library;

class PlayerDbSchema {
  PlayerDbSchema._();

  /// Bump when the table layout changes so a stale copied DB is replaced.
  static const int version = 1;

  /// The relative asset path the generator writes to and the app bundles.
  static const String assetPath = 'assets/db/players.db';

  /// File name used for the writable on-device copy.
  static const String fileName = 'players.db';

  // ── Table / column names (single source of truth) ──
  static const String tPlayers = 'players';
  static const String tLeaguesPlayed = 'player_leagues_played';
  static const String tLeagueTitles = 'player_league_titles';
  static const String tIntlTitles = 'player_international_titles';
  static const String tTeams = 'player_teams';

  static const String cId = 'id';
  static const String cName = 'name';
  static const String cNameLower = 'name_lower';
  static const String cNationality = 'nationality';
  static const String cPhotoUrl = 'photo_url';
  static const String cPlayerId = 'player_id';
  static const String cLeague = 'league';
  static const String cTournament = 'tournament';
  static const String cTeam = 'team';

  /// All DDL statements, executed in order, to build an empty schema.
  static const List<String> createStatements = [
    '''
    CREATE TABLE $tPlayers (
      $cId          TEXT PRIMARY KEY,
      $cName        TEXT NOT NULL,
      $cNameLower   TEXT NOT NULL,
      $cNationality TEXT NOT NULL,
      $cPhotoUrl    TEXT
    )
    ''',
    '''
    CREATE TABLE $tLeaguesPlayed (
      $cPlayerId TEXT NOT NULL REFERENCES $tPlayers($cId) ON DELETE CASCADE,
      $cLeague   TEXT NOT NULL,
      PRIMARY KEY ($cPlayerId, $cLeague)
    )
    ''',
    '''
    CREATE TABLE $tLeagueTitles (
      $cPlayerId TEXT NOT NULL REFERENCES $tPlayers($cId) ON DELETE CASCADE,
      $cLeague   TEXT NOT NULL,
      PRIMARY KEY ($cPlayerId, $cLeague)
    )
    ''',
    '''
    CREATE TABLE $tIntlTitles (
      $cPlayerId   TEXT NOT NULL REFERENCES $tPlayers($cId) ON DELETE CASCADE,
      $cTournament TEXT NOT NULL,
      PRIMARY KEY ($cPlayerId, $cTournament)
    )
    ''',
    '''
    CREATE TABLE $tTeams (
      $cPlayerId TEXT NOT NULL REFERENCES $tPlayers($cId) ON DELETE CASCADE,
      $cTeam     TEXT NOT NULL,
      PRIMARY KEY ($cPlayerId, $cTeam)
    )
    ''',
    'CREATE INDEX idx_players_name_lower ON $tPlayers($cNameLower)',
    'CREATE INDEX idx_players_nationality ON $tPlayers($cNationality)',
    'CREATE INDEX idx_leagues_played_league ON $tLeaguesPlayed($cLeague)',
    'CREATE INDEX idx_league_titles_league ON $tLeagueTitles($cLeague)',
    'CREATE INDEX idx_intl_titles_tournament ON $tIntlTitles($cTournament)',
    'CREATE INDEX idx_player_teams_team ON $tTeams($cTeam)',
  ];
}
