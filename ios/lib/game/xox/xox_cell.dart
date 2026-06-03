import '../../data/player.dart';

/// The state of one cell in the 3x3 XOX grid.
///
/// A cell is either empty or filled with the [Player] the user selected for the
/// intersection of its row and column factors. Because selection is blocked at
/// search time (only valid players are selectable), a filled cell is always a
/// correct answer.
class XoxCell {
  const XoxCell({this.player});

  /// The chosen player, or null while the cell is empty.
  final Player? player;

  bool get isFilled => player != null;

  XoxCell fillWith(Player player) => XoxCell(player: player);
}
