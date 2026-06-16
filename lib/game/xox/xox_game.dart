import '../../data/player.dart';
import 'factor.dart';
import 'factor_pool.dart';
import 'xox_cell.dart';

/// Immutable-ish controller for a single 2-player Football XOX match.
///
/// Players X and O alternate. Naming a valid footballer for an empty cell
/// claims it with the current mark. A footballer may be used at most once per
/// match. The first to complete a line of their mark — any row, any column, or
/// a main diagonal — wins; a full board with no line is a draw.
class XoxGame {
  XoxGame._({
    required this.rows,
    required this.columns,
    required List<XoxCell> cells,
    required this.current,
    required Set<String> usedPlayerIds,
    required this.winner,
    required this.isDraw,
    required this.playerXName,
    required this.playerOName,
  })  : _cells = cells, // ignore: prefer_initializing_formals
        // ignore: prefer_initializing_formals
        _usedPlayerIds = usedPlayerIds;

  /// Starts a fresh match with a newly generated, fully-solvable board.
  ///
  /// [playerXName] and [playerOName] are the display names for the two players.
  factory XoxGame.newMatch({
    List<Player>? players,
    String playerXName = 'Player X',
    String playerOName = 'Player O',
  }) {
    final board = FactorPool.generateBoard(null, players);
    return XoxGame._(
      rows: board.rows,
      columns: board.columns,
      cells: List<XoxCell>.filled(9, const XoxCell()),
      current: Mark.x,
      usedPlayerIds: <String>{},
      winner: Mark.none,
      isDraw: false,
      playerXName: playerXName,
      playerOName: playerOName,
    );
  }

  final List<Factor> rows;
  final List<Factor> columns;
  final List<XoxCell> _cells;
  final Set<String> _usedPlayerIds;

  /// Display name of the X player.
  final String playerXName;

  /// Display name of the O player.
  final String playerOName;

  /// Whose turn it is (X or O). [Mark.none] only when the game is over.
  final Mark current;

  /// The winning mark, or [Mark.none] if no winner yet.
  final Mark winner;

  /// True when the board filled with no winner.
  final bool isDraw;

  /// Returns the display name for the given [mark].
  String nameOf(Mark mark) => mark == Mark.x ? playerXName : playerOName;

  /// Returns the display name of the player whose turn it is.
  String get currentPlayerName => nameOf(current);

  List<XoxCell> get cells => List.unmodifiable(_cells);

  /// Ids of footballers already used this match (cannot be reused).
  Set<String> get usedPlayerIds => Set.unmodifiable(_usedPlayerIds);

  bool get isOver => winner != Mark.none || isDraw;

  int get filledCount => _cells.where((c) => c.isFilled).length;

  XoxCell cellAt(int row, int col) => _cells[row * 3 + col];

  /// Returns a new game state with [player] claiming the cell at (row, col) for
  /// the [current] mark, advancing the turn and recomputing win/draw. The
  /// caller is responsible for only passing valid (factor-satisfying, unused)
  /// players — selection is blocked at search. If the cell is occupied or the
  /// game is over, returns `this` unchanged.
  XoxGame claimCell(int row, int col, Player player) {
    final index = row * 3 + col;
    if (isOver || _cells[index].isFilled) return this;

    final newCells = List<XoxCell>.of(_cells);
    newCells[index] = newCells[index].claim(current, player);

    final newUsed = {..._usedPlayerIds, player.id};
    final newWinner = _findWinner(newCells);
    final boardFull = newCells.every((c) => c.isFilled);
    final draw = newWinner == Mark.none && boardFull;

    // Turn passes only while the game continues.
    final nextMark = (newWinner != Mark.none || draw)
        ? Mark.none
        : (current == Mark.x ? Mark.o : Mark.x);

    return XoxGame._(
      rows: rows,
      columns: columns,
      cells: newCells,
      current: nextMark,
      usedPlayerIds: newUsed,
      winner: newWinner,
      isDraw: draw,
      playerXName: playerXName,
      playerOName: playerOName,
    );
  }

  /// Passes the turn to the other player without claiming a cell (used when the
  /// current player gives up on their search). No-op once the game is over.
  XoxGame passTurn() {
    if (isOver) return this;
    return XoxGame._(
      rows: rows,
      columns: columns,
      cells: _cells,
      current: current == Mark.x ? Mark.o : Mark.x,
      usedPlayerIds: _usedPlayerIds,
      winner: winner,
      isDraw: isDraw,
      playerXName: playerXName,
      playerOName: playerOName,
    );
  }

  /// The 8 winning lines as cell-index triples.
  static const List<List<int>> _lines = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
    [0, 3, 6], [1, 4, 7], [2, 5, 8], // columns
    [0, 4, 8], [2, 4, 6], // main diagonals
  ];

  static Mark _findWinner(List<XoxCell> cells) {
    for (final line in _lines) {
      final a = cells[line[0]].mark;
      if (a != Mark.none &&
          a == cells[line[1]].mark &&
          a == cells[line[2]].mark) {
        return a;
      }
    }
    return Mark.none;
  }
}
