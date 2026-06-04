import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flyball/data/player.dart';
import 'package:flyball/data/player_database.dart';
import 'package:flyball/data/player_db_schema.dart';
import 'package:flyball/data/player_repository.dart';
import 'package:flyball/data/sqlite_player_repository.dart';
import 'package:flyball/game/xox/factor.dart';

/// Seeds an in-memory DB (matching the production schema) with [players] and
/// returns a repository backed by it.
Future<SqlitePlayerRepository> _repoWith(List<Player> players) async {
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      // Each test gets its own isolated in-memory DB.
      singleInstance: false,
      version: PlayerDbSchema.version,
      onCreate: (d, _) async {
        for (final stmt in PlayerDbSchema.createStatements) {
          await d.execute(stmt);
        }
      },
    ),
  );
  for (final p in players) {
    await db.insert(PlayerDbSchema.tPlayers, {
      PlayerDbSchema.cId: p.id,
      PlayerDbSchema.cName: p.name,
      PlayerDbSchema.cNameLower: p.name.toLowerCase(),
      PlayerDbSchema.cNationality: p.nationality,
      PlayerDbSchema.cPhotoUrl: p.photoUrl,
    });
    for (final l in p.leaguesPlayed) {
      await db.insert(PlayerDbSchema.tLeaguesPlayed,
          {PlayerDbSchema.cPlayerId: p.id, PlayerDbSchema.cLeague: l});
    }
    for (final l in p.leagueTitles) {
      await db.insert(PlayerDbSchema.tLeagueTitles,
          {PlayerDbSchema.cPlayerId: p.id, PlayerDbSchema.cLeague: l});
    }
    for (final t in p.internationalTitles) {
      await db.insert(PlayerDbSchema.tIntlTitles,
          {PlayerDbSchema.cPlayerId: p.id, PlayerDbSchema.cTournament: t});
    }
    for (final t in p.teams) {
      await db.insert(PlayerDbSchema.tTeams,
          {PlayerDbSchema.cPlayerId: p.id, PlayerDbSchema.cTeam: t});
    }
  }
  return SqlitePlayerRepository(database: PlayerDatabase.forTesting(db));
}

const _haaland = Player(
  id: 'haaland',
  name: 'Erling Haaland',
  nationality: 'Norway',
  leaguesPlayed: {'Bundesliga', 'Premier League'},
  leagueTitles: {'Premier League'},
  teams: {'Borussia Dortmund', 'Manchester City'},
);

const _messi = Player(
  id: 'messi',
  name: 'Lionel Messi',
  nationality: 'Argentina',
  leaguesPlayed: {'La Liga', 'Ligue 1'},
  leagueTitles: {'La Liga', 'Ligue 1'},
  internationalTitles: {'World Cup', 'Copa America'},
  teams: {'Barcelona', 'PSG'},
);

const _played = Factor(
    type: FactorType.playedLeague,
    label: 'Played in Premier League',
    value: 'Premier League');
const _manCity =
    Factor(type: FactorType.team, label: 'Played for Manchester City', value: 'Manchester City');
const _laLigaWon =
    Factor(type: FactorType.wonLeague, label: 'Won La Liga', value: 'La Liga');

void main() {
  setUpAll(() => sqfliteFfiInit());

  test('returns a player satisfying both factors', () async {
    final repo = await _repoWith([_haaland, _messi]);
    final result =
        await repo.searchValid(query: 'haaland', rowFactor: _played, columnFactor: _manCity);

    expect(result.status, SearchStatus.ok);
    expect(result.players.map((p) => p.id), ['haaland']);
    // Attribute sets are fully reassembled from the junction tables.
    expect(result.players.single.teams, contains('Manchester City'));
    expect(result.players.single.leaguesPlayed, contains('Bundesliga'));
  });

  test('impossible intersection returns empty', () async {
    final repo = await _repoWith([_haaland, _messi]);
    // Haaland never won La Liga; nobody named "haaland" satisfies both.
    final result =
        await repo.searchValid(query: 'haaland', rowFactor: _played, columnFactor: _laLigaWon);

    expect(result.players, isEmpty);
    expect(result.message, isNotNull);
  });

  test('excludeIds filters out used players', () async {
    final repo = await _repoWith([_haaland, _messi]);
    final result = await repo.searchValid(
      query: 'haaland',
      rowFactor: _played,
      columnFactor: _manCity,
      excludeIds: {'haaland'},
    );
    expect(result.players, isEmpty);
  });

  test('queries shorter than 3 chars are rejected', () async {
    final repo = await _repoWith([_haaland]);
    final result =
        await repo.searchValid(query: 'ha', rowFactor: _played, columnFactor: _manCity);

    expect(result.players, isEmpty);
    expect(result.message, contains('3 letters'));
  });

  test('nationality + won-international intersection', () async {
    final repo = await _repoWith([_haaland, _messi]);
    const arg = Factor(
        type: FactorType.nationality, label: 'Argentina', value: 'Argentina');
    const worldCup = Factor(
        type: FactorType.wonInternational,
        label: 'Won World Cup',
        value: 'World Cup');
    final result =
        await repo.searchValid(query: 'messi', rowFactor: arg, columnFactor: worldCup);

    expect(result.players.map((p) => p.id), ['messi']);
  });
}
