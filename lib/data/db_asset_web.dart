import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

import 'player_db_schema.dart';

/// Web path: there is no filesystem, so the IndexedDB-backed FFI web factory
/// (installed in `main.dart`) can't open the bundled asset by file path.
/// Instead we read the asset bytes and import them into the web VFS once, then
/// open that logical path.
///
/// We deliberately do NOT pass `readOnly: true` on web — the IndexedDB VFS
/// needs write access for its own journal; the app simply never issues writes
/// (the player data is search-only).
Future<Database> openAssetDatabase() async {
  const name = PlayerDbSchema.fileName;
  final bytes = await rootBundle.load(PlayerDbSchema.assetPath);
  final data = bytes.buffer.asUint8List(
    bytes.offsetInBytes,
    bytes.lengthInBytes,
  );

  // Seed the web VFS with the bundled DB bytes (idempotent — overwriting a
  // 245 KB read-only DB on each launch is cheap), then open it.
  await databaseFactory.writeDatabaseBytes(name, data);
  return databaseFactory.openDatabase(
    name,
    options: OpenDatabaseOptions(
      onConfigure: (d) => d.execute('PRAGMA foreign_keys = ON'),
    ),
  );
}
