import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'player_db_schema.dart';

/// Native (mobile/desktop) path: copy the bundled read-only asset DB into the
/// writable database directory, then open it.
///
/// Web has no filesystem, so this lives behind a conditional import (see
/// [db_asset_web.dart] for the web counterpart) — `dart:io` must never reach a
/// web build.
Future<Database> openAssetDatabase() async {
  final dir = await getDatabasesPath();
  final path = p.join(dir, PlayerDbSchema.fileName);

  await Directory(dir).create(recursive: true);
  final bytes = await rootBundle.load(PlayerDbSchema.assetPath);
  final data = bytes.buffer.asUint8List(
    bytes.offsetInBytes,
    bytes.lengthInBytes,
  );
  // Always copy from asset to ensure the latest curated database is used.
  await File(path).writeAsBytes(data, flush: true);
  debugPrint('[PlayerDB] Asset copied to $path (${data.length} bytes)');

  return openDatabase(path);
}
