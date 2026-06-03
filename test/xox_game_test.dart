import 'package:flutter_test/flutter_test.dart';
import 'package:flyball/data/player.dart';
import 'package:flyball/game/xox/xox_cell.dart';
import 'package:flyball/game/xox/xox_game.dart';

/// Builds a throwaway player with a unique id for placing marks in tests.
Player _player(String id) =>
    Player(id: id, name: id, nationality: 'Testland');

void main() {
  group('XoxGame', () {
    test('starts with X to move, empty board, no winner', () {
      final g = XoxGame.newMatch();
      expect(g.current, Mark.x);
      expect(g.filledCount, 0);
      expect(g.winner, Mark.none);
      expect(g.isDraw, isFalse);
      expect(g.isOver, isFalse);
    });

    test('claiming a cell alternates turns', () {
      var g = XoxGame.newMatch();
      expect(g.current, Mark.x);
      g = g.claimCell(0, 0, _player('a'));
      expect(g.cellAt(0, 0).mark, Mark.x);
      expect(g.current, Mark.o);
      g = g.claimCell(1, 1, _player('b'));
      expect(g.cellAt(1, 1).mark, Mark.o);
      expect(g.current, Mark.x);
    });

    test('passTurn switches player without claiming', () {
      var g = XoxGame.newMatch();
      g = g.passTurn();
      expect(g.current, Mark.o);
      expect(g.filledCount, 0);
    });

    test('a player id cannot be used twice', () {
      var g = XoxGame.newMatch();
      g = g.claimCell(0, 0, _player('dup'));
      expect(g.usedPlayerIds.contains('dup'), isTrue);
    });

    test('X wins on the top row', () {
      var g = XoxGame.newMatch();
      g = g.claimCell(0, 0, _player('x1')); // X
      g = g.claimCell(1, 0, _player('o1')); // O
      g = g.claimCell(0, 1, _player('x2')); // X
      g = g.claimCell(1, 1, _player('o2')); // O
      g = g.claimCell(0, 2, _player('x3')); // X completes row 0
      expect(g.winner, Mark.x);
      expect(g.isOver, isTrue);
      // No further moves apply.
      final after = g.claimCell(2, 2, _player('x4'));
      expect(after.cellAt(2, 2).isFilled, isFalse);
    });

    test('O wins on the left column', () {
      var g = XoxGame.newMatch();
      g = g.claimCell(0, 1, _player('x1')); // X
      g = g.claimCell(0, 0, _player('o1')); // O
      g = g.claimCell(0, 2, _player('x2')); // X
      g = g.claimCell(1, 0, _player('o2')); // O
      g = g.claimCell(2, 2, _player('x3')); // X
      g = g.claimCell(2, 0, _player('o3')); // O completes col 0
      expect(g.winner, Mark.o);
    });

    test('X wins on the TL-M-BR diagonal', () {
      var g = XoxGame.newMatch();
      g = g.claimCell(0, 0, _player('x1')); // X
      g = g.claimCell(0, 1, _player('o1')); // O
      g = g.claimCell(1, 1, _player('x2')); // X
      g = g.claimCell(0, 2, _player('o2')); // O
      g = g.claimCell(2, 2, _player('x3')); // X completes diagonal
      expect(g.winner, Mark.x);
    });

    test('X wins on the TR-M-BL diagonal', () {
      var g = XoxGame.newMatch();
      g = g.claimCell(0, 2, _player('x1')); // X
      g = g.claimCell(0, 0, _player('o1')); // O
      g = g.claimCell(1, 1, _player('x2')); // X
      g = g.claimCell(0, 1, _player('o2')); // O
      g = g.claimCell(2, 0, _player('x3')); // X completes anti-diagonal
      expect(g.winner, Mark.x);
    });

    test('full board with no line is a draw', () {
      var g = XoxGame.newMatch();
      // Fill order producing no three-in-a-row:
      // X O X
      // X X O
      // O X O
      final moves = <List<int>>[
        [0, 0], // X
        [0, 1], // O
        [0, 2], // X
        [1, 2], // O
        [1, 0], // X
        [2, 0], // O
        [1, 1], // X
        [2, 2], // O
        [2, 1], // X
      ];
      for (var i = 0; i < moves.length; i++) {
        g = g.claimCell(moves[i][0], moves[i][1], _player('p$i'));
      }
      expect(g.filledCount, 9);
      expect(g.winner, Mark.none);
      expect(g.isDraw, isTrue);
      expect(g.isOver, isTrue);
    });
  });
}
