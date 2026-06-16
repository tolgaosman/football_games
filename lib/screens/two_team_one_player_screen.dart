import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/answer_search_service.dart';
import '../data/player.dart';
import '../data/player_database.dart';
import '../game/two_team/two_team_game.dart';
import '../game/xox/factor_art.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/brutalist_button.dart';
import '../widgets/brutalist_card.dart';
import '../widgets/states.dart';

/// **2 Team 1 Player** — a two-player party quiz.
///
/// Tapping "New Teams" spins two slot boxes that land on a random pair of clubs
/// (always one with a shared player). Players then name footballers who turned
/// out for BOTH clubs; the "Answers" button reveals the full list. A manual
/// scoreboard tracks the two players.
class TwoTeamOnePlayerScreen extends StatefulWidget {
  const TwoTeamOnePlayerScreen({super.key});

  @override
  State<TwoTeamOnePlayerScreen> createState() => _TwoTeamOnePlayerScreenState();
}

class _TwoTeamOnePlayerScreenState extends State<TwoTeamOnePlayerScreen> {
  final Random _rng = Random();

  /// The game logic, built once the player corpus is loaded.
  late TwoTeamGame _game;
  bool _loading = true;

  /// Fetches live reference answers; falls back to the local corpus.
  final AnswerSearchService _answerSearch = AnswerSearchService();

  /// The settled club pair.
  late String _teamA;
  late String _teamB;

  /// The (possibly mid-spin) club shown in each box.
  late String _displayA;
  late String _displayB;

  bool _spinning = false;
  Timer? _spinTimer;

  String _p1Name = 'Oyuncu 1';
  String _p2Name = 'Oyuncu 2';
  int _p1Score = 0;
  int _p2Score = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Loads the player corpus from the on-device database, builds the game and
  /// settles the first pair. Falls back to an empty corpus on DB failure.
  Future<void> _load() async {
    List<Player> corpus;
    try {
      corpus = await PlayerDatabase.instance.loadAllPlayers();
    } catch (_) {
      corpus = const [];
    }
    if (!mounted) return;
    final game = TwoTeamGame(corpus);
    final pair = game.randomPair(_rng);
    setState(() {
      _game = game;
      _teamA = _displayA = pair.teamA;
      _teamB = _displayB = pair.teamB;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _spinTimer?.cancel();
    super.dispose();
  }

  void _spin() {
    if (_spinning) return;
    final pool = TwoTeamGame.teams;
    setState(() => _spinning = true);

    // Rapidly flash random clubs in both boxes for the slot effect.
    _spinTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      setState(() {
        _displayA = pool[_rng.nextInt(pool.length)];
        _displayB = pool[_rng.nextInt(pool.length)];
      });
    });

    // Land on a real (answer-guaranteed) pair after ~2 seconds.
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _spinTimer?.cancel();
      final pair = _game.randomPair(_rng);
      setState(() {
        _teamA = _displayA = pair.teamA;
        _teamB = _displayB = pair.teamB;
        _spinning = false;
      });
    });
  }

  Future<void> _editName(bool isPlayerOne) async {
    final controller = TextEditingController(
      text: isPlayerOne ? _p1Name : _p2Name,
    );
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          side: const BorderSide(
              color: AppColors.pitchGreen, width: AppTheme.borderWidth),
        ),
        title: Text('İSİM', style: AppTheme.title()),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTheme.label(16),
          cursorColor: AppColors.pitchGreen,
          decoration: InputDecoration(
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.whiteMuted),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.pitchGreen, width: 2),
            ),
          ),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('İPTAL', style: AppTheme.label(14, color: AppColors.whiteMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text('KAYDET', style: AppTheme.label(14, color: AppColors.pitchGreen)),
          ),
        ],
      ),
    );
    if (result == null) return;
    final trimmed = result.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      if (isPlayerOne) {
        _p1Name = trimmed;
      } else {
        _p2Name = trimmed;
      }
    });
  }

  void _showAnswers() {
    if (_spinning) return;
    // Local corpus answers serve as the offline fallback for the live search.
    final fallback =
        _game.sharedPlayers(_teamA, _teamB).map((p) => p.name).toList();
    showDialog<void>(
      context: context,
      builder: (context) => _AnswersDialog(
        teamA: _teamA,
        teamB: _teamB,
        search: _answerSearch.search(condition1: _teamA, condition2: _teamB),
        fallback: fallback,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('2 TEAM 1 PLAYER', style: AppTheme.heading(20)),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SafeArea(
        child: _loading
            ? const LoadingState()
            : LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      // ── Slot boxes ──
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: SuccessPop(
                                trigger: _spinning ? null : _teamA,
                                child: _TeamSlot(
                                    team: _displayA, spinning: _spinning),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: SuccessPop(
                                trigger: _spinning ? null : _teamB,
                                child: _TeamSlot(
                                    team: _displayB, spinning: _spinning),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // ── Scoreboard ──
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _ScorePanel(
                                name: _p1Name,
                                score: _p1Score,
                                onEditName: () => _editName(true),
                                onIncrement: () => setState(() => _p1Score++),
                                onDecrement: () =>
                                    setState(() => _p1Score = max(0, _p1Score - 1)),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _ScorePanel(
                                name: _p2Name,
                                score: _p2Score,
                                onEditName: () => _editName(false),
                                onIncrement: () => setState(() => _p2Score++),
                                onDecrement: () =>
                                    setState(() => _p2Score = max(0, _p2Score - 1)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      // ── Action buttons ──
                      BrutalistButton(
                        onPressed: _spinning ? null : _spin,
                        child: const Text('YENİ TAKIMLAR'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      BrutalistButton(
                        onPressed: _spinning ? null : _showAnswers,
                        color: AppColors.surface,
                        foregroundColor: AppColors.white,
                        borderColor: AppColors.pitchGreen,
                        child: const Text('CEVAPLAR'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A single slot box showing a club logo (or its name) above the club name.
class _TeamSlot extends StatelessWidget {
  const _TeamSlot({required this.team, required this.spinning});

  final String team;
  final bool spinning;

  @override
  Widget build(BuildContext context) {
    final asset = FactorArtResolver.teamLogoAsset(team);
    return BrutalistCard(
      borderColor: spinning ? AppColors.pitchGreen : AppColors.border,
      soft: !spinning,
      shadowColor: AppColors.pitchGreen,
      shadowOffset: spinning ? const Offset(5, 5) : AppTheme.shadowOffset,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 84,
            child: Center(
              child: asset != null
                  ? Image.asset(
                      asset,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => _logoFallback(team),
                    )
                  : _logoFallback(team),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            team,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.headline(),
          ),
        ],
      ),
    );
  }

  Widget _logoFallback(String team) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          team,
          textAlign: TextAlign.center,
          style: AppTheme.heading(20, color: AppColors.pitchGreen),
        ),
      ),
    );
  }
}

/// A scoreboard column for one player: editable name, score, and +/- buttons.
class _ScorePanel extends StatelessWidget {
  const _ScorePanel({
    required this.name,
    required this.score,
    required this.onEditName,
    required this.onIncrement,
    required this.onDecrement,
  });

  final String name;
  final int score;
  final VoidCallback onEditName;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return BrutalistCard(
      borderColor: AppColors.border,
      soft: true,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onEditName,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.caption(),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const Icon(Icons.edit, size: 14, color: AppColors.whiteMuted),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SuccessPop(
            trigger: score,
            child: Text(
              '$score',
              style: AppTheme.heading(44, color: AppColors.pitchGreen),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: BrutalistButton(
                  onPressed: onDecrement,
                  color: AppColors.surfaceLow,
                  foregroundColor: AppColors.white,
                  borderColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  restingOffset: const Offset(3, 3),
                  child: const Text('−'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: BrutalistButton(
                  onPressed: onIncrement,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  restingOffset: const Offset(3, 3),
                  child: const Text('+'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A scrollable popup listing footballers who played for both clubs.
///
/// While [search] is in flight it shows a loading state, then renders the live
/// LLM names; if the search yields `null` (no key / network / parse failure) it
/// falls back to the on-device [fallback] names.
class _AnswersDialog extends StatefulWidget {
  const _AnswersDialog({
    required this.teamA,
    required this.teamB,
    required this.search,
    required this.fallback,
  });

  final String teamA;
  final String teamB;
  final Future<List<String>?> search;
  final List<String> fallback;

  @override
  State<_AnswersDialog> createState() => _AnswersDialogState();
}

class _AnswersDialogState extends State<_AnswersDialog> {
  bool _loading = true;
  late List<String> _names;

  @override
  void initState() {
    super.initState();
    _names = widget.fallback;
    _resolve();
  }

  Future<void> _resolve() async {
    final live = await widget.search;
    if (!mounted) return;
    setState(() {
      _names = live ?? widget.fallback;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: BrutalistCard(
        color: AppColors.surfaceHigh,
        borderColor: AppColors.pitchGreen,
        padding: const EdgeInsets.all(AppSpacing.lg),
        height: size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.teamA}  ×  ${widget.teamB}',
              textAlign: TextAlign.center,
              style: AppTheme.headline(),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _loading ? 'ARANIYOR…' : '${_names.length} OYUNCU',
              textAlign: TextAlign.center,
              style: AppTheme.overline(color: AppColors.pitchGreen),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: _loading
                  ? const LoadingState(message: 'ARANIYOR…')
                  : _names.isEmpty
                      ? const EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'ORTAK OYUNCU YOK',
                        )
                      : ListView.separated(
                          itemCount: _names.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, i) {
                            return FadeSlideIn(
                              delay: Duration(milliseconds: 30 * i),
                              duration: AppTheme.durMed,
                              child: BrutalistCard(
                                color: AppColors.surfaceLow,
                                borderColor: AppColors.border,
                                shadowOffset: Offset.zero,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.md,
                                ),
                                child: Text(_names[i], style: AppTheme.body()),
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: AppSpacing.lg),
            BrutalistButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('KAPAT'),
            ),
          ],
        ),
      ),
    );
  }
}
