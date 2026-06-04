import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flyball/data/footballer_pool.dart';
import 'package:flyball/data/player.dart';
import 'package:flyball/game/xox/board_solver.dart';
import 'package:flyball/game/xox/factor.dart';
import 'package:flyball/game/xox/factor_pool.dart';

void main() {
  group('FactorPool.generateBoard', () {
    // The board is generated against the real player corpus — at runtime this
    // is the SQLite database, which is built from FootballerPool, so the pool
    // is the canonical offline corpus the tests validate against.
    final corpus = FootballerPool.all;

    test('returns 3 rows and 3 columns', () {
      final board = FactorPool.generateBoard(Random(1), corpus);
      expect(board.rows, hasLength(3));
      expect(board.columns, hasLength(3));
    });

    test('all six factors are unique across many seeds', () {
      for (var seed = 0; seed < 200; seed++) {
        final board = FactorPool.generateBoard(Random(seed), corpus);
        final all = {...board.rows, ...board.columns};
        expect(all, hasLength(6), reason: 'duplicate factor for seed $seed');
      }
    });

    test('is deterministic for a fixed seed', () {
      final a = FactorPool.generateBoard(Random(42), corpus);
      final b = FactorPool.generateBoard(Random(42), corpus);
      expect(a.rows, equals(b.rows));
      expect(a.columns, equals(b.columns));
    });

    test('exposes exactly 59 nationalities', () {
      expect(FactorPool.nationalities, hasLength(59));
    });

    test('never places a nationality on both a row and a column', () {
      for (var seed = 0; seed < 300; seed++) {
        final board = FactorPool.generateBoard(Random(seed), corpus);
        final rowsHaveNation = board.rows.any((f) => f.isNationality);
        final colsHaveNation = board.columns.any((f) => f.isNationality);
        expect(rowsHaveNation && colsHaveNation, isFalse,
            reason: 'nationality on both axes for seed $seed');
      }
    });

    test('never places an international tournament on both axes', () {
      for (var seed = 0; seed < 300; seed++) {
        final board = FactorPool.generateBoard(Random(seed), corpus);
        final rowsHaveIntl = board.rows.any((f) => f.isInternational);
        final colsHaveIntl = board.columns.any((f) => f.isInternational);
        expect(rowsHaveIntl && colsHaveIntl, isFalse,
            reason: 'international on both axes for seed $seed');
      }
    });

    test('every generated board is fully solvable against the real corpus', () {
      // Every one of the 9 cells must be answerable by a player that actually
      // exists in the corpus (FootballerPool, the source the DB is built from).
      expect(corpus, isNotEmpty,
          reason: 'corpus must be non-empty for solvability');
      for (var seed = 0; seed < 200; seed++) {
        final board = FactorPool.generateBoard(Random(seed), corpus);
        expect(
          BoardSolver.boardIsSolvable(board.rows, board.columns, corpus),
          isTrue,
          reason: 'unsolvable cell for seed $seed',
        );
      }
    });
  });

  group('Factor.matches', () {
    final messi = const Player(
      id: 'messi',
      name: 'Lionel Messi',
      nationality: 'Argentina',
      leaguesPlayed: {'La Liga', 'Ligue 1'},
      leagueTitles: {'La Liga'},
      internationalTitles: {'World Cup'},
      teams: {'Barcelona'},
    );

    test('nationality factor matches', () {
      const f = Factor(
          type: FactorType.nationality, label: 'Argentina', value: 'Argentina');
      expect(f.matches(messi), isTrue);
    });

    test('played-league factor matches a league he played in', () {
      const f = Factor(
          type: FactorType.playedLeague,
          label: 'Played in La Liga',
          value: 'La Liga');
      expect(f.matches(messi), isTrue);
    });

    test('won-international factor matches', () {
      const f = Factor(
          type: FactorType.wonInternational,
          label: 'Won World Cup',
          value: 'World Cup');
      expect(f.matches(messi), isTrue);
    });

    test('rejects a league he never won', () {
      const f = Factor(
          type: FactorType.wonLeague,
          label: 'Won Premier League',
          value: 'Premier League');
      expect(f.matches(messi), isFalse);
    });
  });
}
