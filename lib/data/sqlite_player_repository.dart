import '../game/xox/factor.dart';
import 'player_database.dart';
import 'player_db_schema.dart';
import 'player_repository.dart';

/// A [PlayerRepository] backed by the on-device SQLite database.
///
/// "Block at search": the intersection of both cell factors is resolved in SQL,
/// so every returned player is a legal answer. Each factor becomes an `EXISTS`
/// (or column) predicate — the SQL mirror of [Factor.matches] — and the indexed
/// junction tables make the lookup near-instant.
class SqlitePlayerRepository implements PlayerRepository {
  SqlitePlayerRepository({PlayerDatabase? database})
      : _database = database ?? PlayerDatabase.instance;

  final PlayerDatabase _database;

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

    try {
      final db = await _database.open();

      final where = <String>[
        '${PlayerDbSchema.tPlayers}.${PlayerDbSchema.cNameLower} LIKE ?',
      ];
      final args = <Object?>['%${trimmed.toLowerCase()}%'];

      for (final factor in [rowFactor, columnFactor]) {
        final clause = _clauseFor(factor);
        where.add(clause.sql);
        args.addAll(clause.args);
      }

      if (excludeIds.isNotEmpty) {
        final placeholders = List.filled(excludeIds.length, '?').join(',');
        where.add('${PlayerDbSchema.tPlayers}.${PlayerDbSchema.cId} '
            'NOT IN ($placeholders)');
        args.addAll(excludeIds);
      }

      final idRows = await db.rawQuery(
        'SELECT ${PlayerDbSchema.cId} FROM ${PlayerDbSchema.tPlayers} '
        'WHERE ${where.join(' AND ')} '
        'ORDER BY ${PlayerDbSchema.cName} '
        'LIMIT 50',
        args,
      );

      final ids = [for (final r in idRows) r[PlayerDbSchema.cId] as String];
      final players = await _database.playersByIds(ids);
      // Preserve the name-ordering from the id query.
      final byId = {for (final p in players) p.id: p};
      final ordered = [
        for (final id in ids)
          if (byId[id] != null) byId[id]!,
      ];

      return SearchResult(
        status: SearchStatus.ok,
        players: ordered,
        message: ordered.isEmpty
            ? 'No player found matching both categories. Try another name.'
            : null,
      );
    } catch (e) {
      return SearchResult(
        status: SearchStatus.error,
        players: const [],
        message: 'Search failed: $e',
      );
    }
  }

  /// The SQL predicate mirroring [Factor.matches] for the players row in scope.
  _Clause _clauseFor(Factor factor) {
    final pid = '${PlayerDbSchema.tPlayers}.${PlayerDbSchema.cId}';
    switch (factor.type) {
      case FactorType.nationality:
        return _Clause(
          '${PlayerDbSchema.tPlayers}.${PlayerDbSchema.cNationality} = ?',
          [factor.value],
        );
      case FactorType.playedLeague:
        return _existsClause(
            PlayerDbSchema.tLeaguesPlayed, PlayerDbSchema.cLeague, factor.value, pid);
      case FactorType.wonLeague:
        return _existsClause(
            PlayerDbSchema.tLeagueTitles, PlayerDbSchema.cLeague, factor.value, pid);
      case FactorType.wonInternational:
        return _existsClause(
            PlayerDbSchema.tIntlTitles, PlayerDbSchema.cTournament, factor.value, pid);
      case FactorType.team:
        return _existsClause(
            PlayerDbSchema.tTeams, PlayerDbSchema.cTeam, factor.value, pid);
    }
  }

  _Clause _existsClause(
      String table, String column, String value, String playerIdRef) {
    return _Clause(
      'EXISTS (SELECT 1 FROM $table '
      'WHERE $table.${PlayerDbSchema.cPlayerId} = $playerIdRef '
      'AND $table.$column = ?)',
      [value],
    );
  }
}

class _Clause {
  const _Clause(this.sql, this.args);
  final String sql;
  final List<Object?> args;
}
