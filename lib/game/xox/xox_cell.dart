import '../../data/player.dart';

/// Which player owns a cell (or none yet).
enum Mark { none, x, o }

/// The state of one cell in the 3x3 XOX grid.
///
/// A cell is empty ([Mark.none]) or claimed by player X or O. When claimed it
/// also holds the [Player] (footballer) that was named to win it. Because
/// selection is blocked at search (only valid players are selectable), a
/// claimed cell is always a correct answer.
class XoxCell {
  const XoxCell({this.mark = Mark.none, this.player});

  /// The owner of this cell.
  final Mark mark;

  /// The footballer named to claim the cell, or null while empty.
  final Player? player;

  bool get isFilled => mark != Mark.none;

  XoxCell claim(Mark mark, Player player) =>
      XoxCell(mark: mark, player: player);

  XoxCell fillWith(Player player) =>
      XoxCell(mark: Mark.x, player: player);
}
