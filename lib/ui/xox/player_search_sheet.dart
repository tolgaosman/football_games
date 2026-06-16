import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/player.dart';
import '../../data/player_repository.dart';
import '../../game/xox/factor.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animations.dart';
import '../../widgets/brutalist_card.dart';
import '../../widgets/factor_image.dart';
import '../../widgets/states.dart';

/// Modal bottom sheet for picking a player to fill an XOX cell.
///
/// Search is "blocked at source": [PlayerRepository.searchValid] only returns
/// players that satisfy BOTH the [rowFactor] and [columnFactor], so anything
/// the user can tap is a legal answer. Loading, empty, no-key and error states
/// are all rendered inline in the brutalist style.
///
/// Returns the selected [Player] via [Navigator.pop], or null if dismissed.
Future<Player?> showPlayerSearchSheet({
  required BuildContext context,
  required PlayerRepository repository,
  required Factor rowFactor,
  required Factor columnFactor,
  Set<String> excludeIds = const {},
}) {
  return showModalBottomSheet<Player>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PlayerSearchSheet(
      repository: repository,
      rowFactor: rowFactor,
      columnFactor: columnFactor,
      excludeIds: excludeIds,
    ),
  );
}

class _PlayerSearchSheet extends StatefulWidget {
  const _PlayerSearchSheet({
    required this.repository,
    required this.rowFactor,
    required this.columnFactor,
    required this.excludeIds,
  });

  final PlayerRepository repository;
  final Factor rowFactor;
  final Factor columnFactor;
  final Set<String> excludeIds;

  @override
  State<_PlayerSearchSheet> createState() => _PlayerSearchSheetState();
}

class _PlayerSearchSheetState extends State<_PlayerSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  bool _loading = false;
  SearchResult? _result;
  int _requestId = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _runSearch(value));
  }

  Future<void> _runSearch(String query) async {
    final id = ++_requestId;
    if (query.trim().length < 3) {
      setState(() {
        _loading = false;
        _result = null;
      });
      return;
    }
    setState(() => _loading = true);
    SearchResult result;
    try {
      result = await widget.repository
          .searchValid(
            query: query,
            rowFactor: widget.rowFactor,
            columnFactor: widget.columnFactor,
            excludeIds: widget.excludeIds,
          )
          // Safety net so a hung/unreachable player service can never leave the
          // spinner spinning forever.
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      result = const SearchResult(
        status: SearchStatus.error,
        players: [],
        message: 'Search timed out. Check the connection and try again.',
      );
    }
    // Ignore stale responses from earlier keystrokes.
    if (!mounted || id != _requestId) return;
    setState(() {
      _loading = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceHigh,
            border: Border(
              top: BorderSide(
                  color: AppColors.pitchGreen, width: AppTheme.borderWidth),
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 32,
                offset: Offset(0, -8),
              ),
            ],
          ),
          // Reserve space for the keyboard so the fixed header + search field
          // are pushed above it instead of overflowing the sheet.
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            children: [
              _buildHandleAndHeader(),
              _buildSearchField(),
              const SizedBox(height: AppSpacing.sm),
              Expanded(child: _buildBody(scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandleAndHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.sm),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  'FIND A PLAYER',
                  style: AppTheme.title(),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: AppColors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // The two factor "chips" the player must satisfy.
          Row(
            children: [
              Expanded(child: _FactorChip(factor: widget.rowFactor)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('×',
                    style: TextStyle(
                        color: AppColors.pitchGreen,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
              ),
              Expanded(child: _FactorChip(factor: widget.columnFactor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: BrutalistCard(
        color: AppColors.surface,
        borderColor: AppColors.white,
        shadowOffset: const Offset(4, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppColors.pitchGreen),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onChanged,
                style: AppTheme.label(17),
                cursorColor: AppColors.pitchGreen,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search footballers…',
                  hintStyle: AppTheme.label(16, color: AppColors.whiteMuted),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            if (_controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear_rounded,
                    color: AppColors.whiteMuted, size: 20),
                onPressed: () {
                  _controller.clear();
                  _onChanged('');
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ScrollController scrollController) {
    if (_loading) {
      return const LoadingState(message: 'SEARCHING…');
    }

    final result = _result;
    if (result == null) {
      return const EmptyState(
        icon: Icons.sports_soccer_rounded,
        title: 'SEARCH AWAY',
        message:
            'Type a name to find a player who fits both categories above.',
      );
    }

    if (result.isEmpty) {
      if (result.status == SearchStatus.error) {
        return ErrorState(
          title: 'SEARCH FAILED',
          message: result.message ??
              'Search timed out. Check the connection and try again.',
        );
      }
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'NO MATCHES',
        message: result.message ??
            'No player found that satisfies BOTH categories. Try another name.',
      );
    }

    final hasBanner = result.message != null;
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxl),
      itemCount: result.players.length + (hasBanner ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        if (hasBanner && index == 0) {
          return _Banner(message: result.message!, status: result.status);
        }
        final dataIndex = index - (hasBanner ? 1 : 0);
        final player = result.players[dataIndex];
        return FadeSlideIn(
          delay: Duration(milliseconds: 30 * dataIndex),
          duration: AppTheme.durMed,
          child: _PlayerTile(
            player: player,
            onTap: () => Navigator.of(context).pop(player),
          ),
        );
      },
    );
  }
}

class _FactorChip extends StatelessWidget {
  const _FactorChip({required this.factor});
  final Factor factor;

  @override
  Widget build(BuildContext context) {
    return BrutalistCard(
      color: AppColors.surfaceLow,
      borderColor: AppColors.pitchGreen,
      shadowOffset: Offset.zero,
      radius: 10,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FactorImage(
            factor: factor,
            imageSize: 36,
            textColor: AppColors.pitchGreen,
          ),
          const SizedBox(height: 6),
          Text(
            factor.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTheme.label(12,
                color: AppColors.pitchGreen, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({required this.player, required this.onTap});
  final Player player;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SpringScale(
      onTap: onTap,
      child: BrutalistCard(
        color: AppColors.surface,
        borderColor: AppColors.border,
        shadowOffset: const Offset(4, 4),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            _Avatar(player: player),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.heading(18),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    player.nationality,
                    style: AppTheme.label(13, color: AppColors.whiteMuted),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.pitchGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppColors.black, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.player});
  final Player player;

  @override
  Widget build(BuildContext context) {
    final initials = player.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .map((p) => p[0])
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.pitchGreen, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: player.photoUrl != null
          ? Image.network(
              player.photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _initialsText(initials),
            )
          : _initialsText(initials),
    );
  }

  Widget _initialsText(String initials) => Text(
        initials,
        style: AppTheme.heading(16, color: AppColors.pitchGreen),
      );
}

class _Banner extends StatelessWidget {
  const _Banner({required this.message, required this.status});
  final String message;
  final SearchStatus status;

  @override
  Widget build(BuildContext context) {
    final color =
        status == SearchStatus.error ? AppColors.danger : AppColors.pitchGreen;
    return BrutalistCard(
      color: AppColors.surfaceLow,
      borderColor: color,
      shadowOffset: Offset.zero,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: AppTheme.label(12.5, color: AppColors.whiteMuted)),
          ),
        ],
      ),
    );
  }
}

