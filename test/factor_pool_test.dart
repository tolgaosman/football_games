import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:flyball/data/player.dart';
import 'package:flyball/game/xox/factor_pool.dart';

void main() {
  group('FactorPool.generateBoard', () {
    test('empty corpus yields a 3+3 board and never throws', () {
      // Regression guard: an empty corpus (e.g. the player DB failed to open)
      // used to crash on `pool.reduce` and leave the XOX screen stuck loading.
      final board = FactorPool.generateBoard(Random(0), const <Player>[]);
      expect(board.rows, hasLength(3));
      expect(board.columns, hasLength(3));
      // All six headers must be unique (core game rule).
      expect({...board.rows, ...board.columns}, hasLength(6));
    });

    test('null corpus also yields a valid board', () {
      final board = FactorPool.generateBoard(Random(1));
      expect(board.rows, hasLength(3));
      expect(board.columns, hasLength(3));
      expect({...board.rows, ...board.columns}, hasLength(6));
    });
  });
}
