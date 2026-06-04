// Builds the on-device player SQLite database from the curated FootballerPool.
//
// Run from the project root with the desktop FFI backend:
//
//   dart run scratch/build_db.dart
//
// Output: assets/db/players.db (overwritten each run). Re-run whenever the
// FootballerPool data changes. The schema comes from PlayerDbSchema so the
// generated DB always matches what the app expects at runtime.

import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flyball/data/footballer_pool.dart';
import 'package:flyball/data/player.dart';
import 'package:flyball/data/player_db_schema.dart';

Future<void> main() async {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;

  final outPath = '${Directory.current.path}/${PlayerDbSchema.assetPath}';
  final outFile = File(outPath);
  await outFile.parent.create(recursive: true);
  if (await outFile.exists()) {
    await outFile.delete();
  }

  final db = await factory.openDatabase(
    outPath,
    options: OpenDatabaseOptions(
      version: PlayerDbSchema.version,
      onConfigure: (d) => d.execute('PRAGMA foreign_keys = ON'),
      onCreate: (d, _) async {
        for (final stmt in PlayerDbSchema.createStatements) {
          await d.execute(stmt);
        }
      },
    ),
  );

  final players = FootballerPool.all;
  await db.transaction((txn) async {
    final batch = txn.batch();
    for (final p in players) {
      _insertPlayer(batch, p);
    }
    await batch.commit(noResult: true);
  });

  final countRows =
      await db.rawQuery('SELECT COUNT(*) AS n FROM ${PlayerDbSchema.tPlayers}');
  final count = countRows.first['n'] as int;
  await db.close();

  stdout.writeln('Wrote ${PlayerDbSchema.assetPath}');
  stdout.writeln('Players in pool: ${players.length}, rows in DB: $count');
  if (count != players.length) {
    stderr.writeln('WARNING: row count != pool size (duplicate ids?)');
    exitCode = 1;
  }
}

void _insertPlayer(Batch batch, Player p) {
  batch.insert(PlayerDbSchema.tPlayers, {
    PlayerDbSchema.cId: p.id,
    PlayerDbSchema.cName: p.name,
    PlayerDbSchema.cNameLower: p.name.toLowerCase(),
    PlayerDbSchema.cNationality: p.nationality,
    PlayerDbSchema.cPhotoUrl: p.photoUrl,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  for (final league in p.leaguesPlayed) {
    batch.insert(PlayerDbSchema.tLeaguesPlayed, {
      PlayerDbSchema.cPlayerId: p.id,
      PlayerDbSchema.cLeague: league,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
  for (final league in p.leagueTitles) {
    batch.insert(PlayerDbSchema.tLeagueTitles, {
      PlayerDbSchema.cPlayerId: p.id,
      PlayerDbSchema.cLeague: league,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
  for (final tournament in p.internationalTitles) {
    batch.insert(PlayerDbSchema.tIntlTitles, {
      PlayerDbSchema.cPlayerId: p.id,
      PlayerDbSchema.cTournament: tournament,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
  for (final team in p.teams) {
    batch.insert(PlayerDbSchema.tTeams, {
      PlayerDbSchema.cPlayerId: p.id,
      PlayerDbSchema.cTeam: team,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}
