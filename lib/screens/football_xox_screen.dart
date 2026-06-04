import 'package:flutter/material.dart';

import '../data/api_football_repository.dart';
import '../data/player_repository.dart';
import '../game/xox/factor.dart';
import '../game/xox/xox_cell.dart';
import '../game/xox/xox_game.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../ui/xox/player_search_sheet.dart';
import '../widgets/brutalist_button.dart';
import '../widgets/brutalist_card.dart';
import '../widgets/factor_image.dart';

/// Football XOX: a two-player (X vs O) tic-tac-toe over a 3x3 trivia grid.
///
/// Each row and column has a random, unique [Factor], and the board is always
/// fully solvable. Players alternate; naming a footballer who satisfies a
/// cell's row AND column factor claims it with the current mark. A footballer
/// may be used once per match. First to complete a row, column, or diagonal of
/// their mark wins; a full board with no line is a draw.
class FootballXoxScreen extends StatefulWidget {
  const FootballXoxScreen({super.key, this.repository});

  /// Injectable for testing; defaults to the API-backed repository.
  final PlayerRepository? repository;

  @override
  State<FootballXoxScreen> createState() => _FootballXoxScreenState();
}

class _FootballXoxScreenState extends State<FootballXoxScreen> {
  late PlayerRepository _repository;
  late XoxGame _game;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ApiFootballRepository();
    _game = XoxGame.newMatch();
  }

  Future<void> _onCellTapped(int row, int col) async {
    if (_game.isOver || _game.cellAt(row, col).isFilled) return;

    final player = await showPlayerSearchSheet(
      context: context,
      repository: _repository,
      rowFactor: _game.rows[row],
      columnFactor: _game.columns[col],
      excludeIds: _game.usedPlayerIds,
    );

    if (!mounted) return;

    if (player != null) {
      // Valid pick claims the cell and passes the turn.
      setState(() => _game = _game.claimCell(row, col, player));
    } else {
      // Gave up on the search → forfeit the turn (cell stays open).
      setState(() => _game = _game.passTurn());
    }
  }

  void _newGame() {
    setState(() => _game = XoxGame.newMatch());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FOOTBALL XOX'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'New game',
              onPressed: _newGame,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _StatusBar(game: _game),
              const SizedBox(height: 16),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Center(child: _buildBoard(constraints));
                  },
                ),
              ),
              if (_game.isOver) ...[
                const SizedBox(height: 12),
                _ResultBanner(game: _game, onPlayAgain: _newGame),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the 4x4 visual layout: an empty corner + 3 column headers on top,
  /// 3 row headers down the left, and the 3x3 grid. Scales to fit.
  Widget _buildBoard(BoxConstraints constraints) {
    final side = constraints.biggest.shortestSide.clamp(0.0, 560.0);
    const spacing = 8.0;

    return SizedBox(
      width: side,
      height: side,
      child: Column(
        children: [
          // --- Header row: empty corner + 3 column factors. ---
          Expanded(
            child: Row(
              children: [
                const Expanded(child: SizedBox.shrink()),
                for (final col in _game.columns)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(spacing / 2),
                      child: _HeaderCell(factor: col),
                    ),
                  ),
              ],
            ),
          ),
          // --- Three body rows: row factor + 3 cells each. ---
          for (int r = 0; r < 3; r++)
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(spacing / 2),
                      child: _HeaderCell(factor: _game.rows[r]),
                    ),
                  ),
                  for (int c = 0; c < 3; c++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(spacing / 2),
                        child: _GridCell(
                          cell: _game.cellAt(r, c),
                          enabled: !_game.isOver,
                          onTap: () => _onCellTapped(r, c),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Colour for a mark (X = pitch green, O = white).
Color _markColor(Mark mark) =>
    mark == Mark.x ? AppColors.pitchGreen : AppColors.white;

String _markLabel(Mark mark) => mark == Mark.x ? 'X' : 'O';

/// Turn indicator / score header.
class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.game});
  final XoxGame game;

  @override
  Widget build(BuildContext context) {
    final String text;
    final Color color;
    if (game.winner != Mark.none) {
      text = 'PLAYER ${_markLabel(game.winner)} WINS!';
      color = _markColor(game.winner);
    } else if (game.isDraw) {
      text = "IT'S A DRAW";
      color = AppColors.whiteMuted;
    } else {
      text = "PLAYER ${_markLabel(game.current)}'S TURN";
      color = _markColor(game.current);
    }

    return BrutalistCard(
      color: AppColors.surface,
      borderColor: color,
      shadowOffset: const Offset(4, 4),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          // Turn token chip.
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color, width: 2.5),
            ),
            child: Text(
              game.isOver ? '🏁' : _markLabel(game.current),
              style: AppTheme.heading(18, color: color),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: AppTheme.heading(18, color: color),
            ),
          ),
          Text('${game.filledCount}/9',
              style: AppTheme.label(14, color: AppColors.whiteMuted)),
        ],
      ),
    );
  }
}

/// Win/draw banner with a "play again" button.
class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.game, required this.onPlayAgain});
  final XoxGame game;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    final won = game.winner != Mark.none;
    final color = won ? _markColor(game.winner) : AppColors.whiteMuted;
    return BrutalistCard(
      color: AppColors.surface,
      borderColor: color,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              won
                  ? 'Player ${_markLabel(game.winner)} completed a line!'
                  : 'No more moves — nobody got a line.',
              style: AppTheme.label(14, color: AppColors.white),
            ),
          ),
          const SizedBox(width: 12),
          BrutalistButton(
            onPressed: onPlayAgain,
            expand: false,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: const Text('PLAY AGAIN'),
          ),
        ],
      ),
    );
  }
}

/// A row/column header showing its factor image (icon-only, text fallback).
class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.factor});
  final Factor factor;

  @override
  Widget build(BuildContext context) {
    return BrutalistCard(
      color: AppColors.pitchGreen,
      borderColor: AppColors.black,
      shadowOffset: const Offset(3, 3),
      radius: 12,
      padding: const EdgeInsets.all(6),
      alignment: Alignment.center,
      child: FactorImage(factor: factor, imageSize: 42),
    );
  }
}

/// A single playable grid cell — empty (tappable) or claimed by X/O.
class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.cell,
    required this.enabled,
    required this.onTap,
  });
  final XoxCell cell;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final filled = cell.isFilled;
    final markColor = filled ? _markColor(cell.mark) : AppColors.white;
    return GestureDetector(
      onTap: (filled || !enabled) ? null : onTap,
      child: BrutalistCard(
        color: filled ? AppColors.surface : AppColors.surfaceLow,
        borderColor: filled ? markColor : AppColors.white,
        shadowOffset: const Offset(3, 3),
        radius: 12,
        padding: const EdgeInsets.all(4),
        alignment: Alignment.center,
        child: filled ? _claimedContent(cell) : _emptyContent(),
      ),
    );
  }

  Widget _emptyContent() {
    return const Icon(Icons.add_rounded, color: AppColors.whiteMuted, size: 28);
  }

  Widget _claimedContent(XoxCell cell) {
    final player = cell.player!;
    final markColor = _markColor(cell.mark);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle_rounded, color: markColor, size: 20),
        const SizedBox(height: 4),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: 110,
              child: Text(
                player.name,
                textAlign: TextAlign.center,
                maxLines: 3,
                style: AppTheme.label(12,
                    color: AppColors.white, weight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
