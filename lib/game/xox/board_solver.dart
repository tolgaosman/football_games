import '../../data/player.dart';
import 'factor.dart';

/// Solvability helpers for the XOX board.
///
/// A cell (row factor × column factor) is "solvable" when at least one player
/// in the supplied corpus satisfies BOTH factors. The board generator uses this
/// to guarantee every one of the 9 cells is answerable.
class BoardSolver {
  BoardSolver._();

  /// True when some player in [players] satisfies both [row] and [column].
  static bool cellHasSolution(
    Factor row,
    Factor column,
    List<Player> players,
  ) {
    for (final player in players) {
      if (row.matches(player) && column.matches(player)) return true;
    }
    return false;
  }

  /// True when ALL 9 cells of the given row/column factors are solvable.
  static bool boardIsSolvable(
    List<Factor> rows,
    List<Factor> columns,
    List<Player> players,
  ) {
    for (final row in rows) {
      for (final column in columns) {
        if (!cellHasSolution(row, column, players)) return false;
      }
    }
    return true;
  }
}
