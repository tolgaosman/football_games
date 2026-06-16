import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'player.dart';
import 'player_db_schema.dart';
// Opens the bundled read-only asset DB. The implementation is platform-specific
// (file copy on mobile/desktop, IndexedDB VFS import on web) and selected at
// compile time so `dart:io` never reaches a web build.
import 'db_asset_io.dart' if (dart.library.js_interop) 'db_asset_web.dart';

/// Opens and reads the on-device player SQLite database.
///
/// The database ships as a read-only asset ([PlayerDbSchema.assetPath]) built
/// by `scratch/build_db.dart` from the curated player data. On first
/// launch the asset is copied into the app's writable database directory; from
/// then on it is opened from there. A singleton holds the open connection so
/// the whole app shares one handle.
class PlayerDatabase {
  PlayerDatabase._();

  /// Wraps an already-open [Database], skipping the asset-copy step. Intended
  /// for tests that seed an in-memory database via `sqflite_common_ffi`.
  PlayerDatabase.forTesting(Database db) {
    _db = db;
  }

  static final PlayerDatabase instance = PlayerDatabase._();

  Database? _db;
  Future<Database>? _opening;

  /// Returns the shared open database, opening (and copying the asset on first
  /// run) if needed. Concurrent callers await the same open operation.
  /// If the previous open attempt failed, retries from scratch.
  Future<Database> open() {
    final existing = _db;
    if (existing != null) return Future.value(existing);
    return _opening ??= _openInternal();
  }

  Future<Database> _openInternal() async {
    try {
      // Platform-specific open (file copy on mobile/desktop, IndexedDB VFS
      // import on web), selected via the conditional import above.
      final db = await openAssetDatabase();
      _db = db;
      debugPrint('[PlayerDB] Database opened successfully');
      return db;
    } catch (e) {
      // Clear the cached future so the next call retries instead of returning
      // the same failed future forever.
      _opening = null;
      debugPrint('[PlayerDB] Failed to open database: $e');
      rethrow;
    }
  }

  /// Loads every player with all attribute sets populated — the corpus fed to
  /// [FactorPool.generateBoard] so board solvability is checked against the DB.
  Future<List<Player>> loadAllPlayers() async {
    final db = await open();
    final rows = await db.query(PlayerDbSchema.tPlayers);
    debugPrint('[PlayerDB] players table: ${rows.length} rows');

    final played = await _groupByPlayer(
        db, PlayerDbSchema.tLeaguesPlayed, PlayerDbSchema.cLeague);
    final titles = await _groupByPlayer(
        db, PlayerDbSchema.tLeagueTitles, PlayerDbSchema.cLeague);
    final intl = await _groupByPlayer(
        db, PlayerDbSchema.tIntlTitles, PlayerDbSchema.cTournament);
    final teams = await _groupByPlayer(
        db, PlayerDbSchema.tTeams, PlayerDbSchema.cTeam);
    debugPrint('[PlayerDB] Attribute maps: played=${played.length}, '
        'titles=${titles.length}, intl=${intl.length}, teams=${teams.length}');

    final result = [
      for (final row in rows)
        _rowToPlayer(
          row,
          leaguesPlayed: played[row[PlayerDbSchema.cId]] ?? const {},
          leagueTitles: titles[row[PlayerDbSchema.cId]] ?? const {},
          internationalTitles: intl[row[PlayerDbSchema.cId]] ?? const {},
          teams: teams[row[PlayerDbSchema.cId]] ?? const {},
        ),
    ];
    debugPrint('[PlayerDB] Built ${result.length} Player objects');
    return result;
  }

  /// Builds full [Player] objects for the given player [ids], loading their
  /// attribute sets. Used by the repository after a cheap id-only filter query.
  Future<List<Player>> playersByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final db = await open();
    final placeholders = List.filled(ids.length, '?').join(',');

    final rows = await db.query(
      PlayerDbSchema.tPlayers,
      where: '${PlayerDbSchema.cId} IN ($placeholders)',
      whereArgs: ids,
    );
    final played = await _groupByPlayer(
        db, PlayerDbSchema.tLeaguesPlayed, PlayerDbSchema.cLeague, ids);
    final titles = await _groupByPlayer(
        db, PlayerDbSchema.tLeagueTitles, PlayerDbSchema.cLeague, ids);
    final intl = await _groupByPlayer(
        db, PlayerDbSchema.tIntlTitles, PlayerDbSchema.cTournament, ids);
    final teams = await _groupByPlayer(
        db, PlayerDbSchema.tTeams, PlayerDbSchema.cTeam, ids);

    return [
      for (final row in rows)
        _rowToPlayer(
          row,
          leaguesPlayed: played[row[PlayerDbSchema.cId]] ?? const {},
          leagueTitles: titles[row[PlayerDbSchema.cId]] ?? const {},
          internationalTitles: intl[row[PlayerDbSchema.cId]] ?? const {},
          teams: teams[row[PlayerDbSchema.cId]] ?? const {},
        ),
    ];
  }

  /// Reads a junction table into a map of player_id → value set. When [ids] is
  /// given, only those players' rows are fetched.
  Future<Map<String, Set<String>>> _groupByPlayer(
    Database db,
    String table,
    String valueColumn, [
    List<String>? ids,
  ]) async {
    final rows = await db.query(
      table,
      columns: [PlayerDbSchema.cPlayerId, valueColumn],
      where: ids == null
          ? null
          : '${PlayerDbSchema.cPlayerId} IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: ids,
    );
    final map = <String, Set<String>>{};
    for (final row in rows) {
      final id = row[PlayerDbSchema.cPlayerId] as String;
      (map[id] ??= <String>{}).add(row[valueColumn] as String);
    }
    return map;
  }

  Player _rowToPlayer(
    Map<String, Object?> row, {
    required Set<String> leaguesPlayed,
    required Set<String> leagueTitles,
    required Set<String> internationalTitles,
    required Set<String> teams,
  }) {
    return Player(
      id: row[PlayerDbSchema.cId] as String,
      name: row[PlayerDbSchema.cName] as String,
      nationality: row[PlayerDbSchema.cNationality] as String,
      photoUrl: row[PlayerDbSchema.cPhotoUrl] as String?,
      leaguesPlayed: leaguesPlayed,
      leagueTitles: leagueTitles,
      internationalTitles: internationalTitles,
      teams: teams,
    );
  }
}
