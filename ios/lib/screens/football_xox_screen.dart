import 'package:flutter/material.dart';

import '../data/api_football_repository.dart';
import '../data/player.dart';
import '../data/player_repository.dart';
import '../game/xox/factor.dart';
import '../game/xox/factor_pool.dart';
import '../game/xox/xox_cell.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../ui/xox/player_search_sheet.dart';
import '../widgets/brutalist_card.dart';

/// The Football XOX game: a 3x3 trivia grid.
///
/// Each row and column is assigned a random, unique [Factor]. To fill a cell
/// the user must name a footballer who satisfies BOTH the row and column
/// factor. Selection is blocked at search (only valid players are selectable),
/// so a filled cell is always correct.
class FootballXoxScreen extends StatefulWidget {
  const FootballXoxScreen({super.key, this.repository});

  /// Injectable for testing; defaults to the API-backed repository.
  final PlayerRepository? repository;

  @override
  State<FootballXoxScreen> createState() => _FootballXoxScreenState();
}

class _FootballXoxScreenState extends State<FootballXoxScreen> {
  late PlayerRepository _repository;
  late List<Factor> _rows;
  late List<Factor> _columns;

  /// 3x3 grid in row-major order (9 cells).
  late List<XoxCell> _cells;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ApiFootballRepository();
    _newBoard();
  }

  void _newBoard() {
    final board = FactorPool.generateBoard();
    _rows = board.rows;
    _columns = board.columns;
    _cells = List<XoxCell>.filled(9, const XoxCell());
  }

  int get _filledCount => _cells.where((c) => c.isFilled).length;

  Future<void> _onCellTapped(int row, int col) async {
    final index = row * 3 + col;
    if (_cells[index].isFilled) return;

    final player = await showPlayerSearchSheet(
      context: context,
      repository: _repository,
      rowFactor: _rows[row],
      columnFactor: _columns[col],
    );

    if (player != null && mounted) {
      setState(() => _cells[index] = _cells[index].fillWith(player));
    }
  }

  void _resetBoard() {
    setState(_newBoard);
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
              tooltip: 'New board',
              onPressed: _resetBoard,
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
              _ScoreBar(filled: _filledCount),
              const SizedBox(height: 16),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Center(
                      child: _buildBoard(constraints),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the 4x4 visual layout: an empty corner + 3 column headers on top,
  /// 3 row headers down the left, and the 3x3 grid. Scales to fit.
  Widget _buildBoard(BoxConstraints constraints) {
    // Use the smaller dimension so the square board never overflows.
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
                for (final col in _columns)
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
                      child: _HeaderCell(factor: _rows[r]),
                    ),
                  ),
                  for (int c = 0; c < 3; c++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(spacing / 2),
                        child: _GridCell(
                          cell: _cells[r * 3 + c],
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

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.filled});
  final int filled;

  @override
  Widget build(BuildContext context) {
    final complete = filled == 9;
    return BrutalistCard(
      color: AppColors.surface,
      borderColor: complete ? AppColors.pitchGreen : AppColors.white,
      shadowOffset: const Offset(4, 4),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.sports_soccer_rounded, color: AppColors.pitchGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              complete ? 'BOARD COMPLETE!' : 'PICK A PLAYER FOR EACH SQUARE',
              style: AppTheme.label(14,
                  color: complete ? AppColors.pitchGreen : AppColors.white,
                  weight: FontWeight.w700),
            ),
          ),
          Text('$filled/9', style: AppTheme.heading(22, color: AppColors.pitchGreen)),
        ],
      ),
    );
  }
}

/// A row/column header showing its factor label.
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
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 120,
          child: Text(
            factor.label,
            textAlign: TextAlign.center,
            style: AppTheme.label(13,
                color: AppColors.black, weight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

/// A single playable grid cell — empty (tappable) or filled with a player.
class _GridCell extends StatelessWidget {
  const _GridCell({required this.cell, required this.onTap});
  final XoxCell cell;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final filled = cell.isFilled;
    return GestureDetector(
      onTap: filled ? null : onTap,
      child: BrutalistCard(
        color: filled ? AppColors.surface : AppColors.surfaceLow,
        borderColor: filled ? AppColors.pitchGreen : AppColors.white,
        shadowOffset: const Offset(3, 3),
        radius: 12,
        padding: const EdgeInsets.all(6),
        alignment: Alignment.center,
        child: filled ? _filledContent(cell.player!) : _emptyContent(),
      ),
    );
  }

  Widget _emptyContent() {
    return const Icon(Icons.add_rounded, color: AppColors.whiteMuted, size: 28);
  }

  Widget _filledContent(Player player) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_rounded,
            color: AppColors.pitchGreen, size: 22),
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
