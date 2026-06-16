import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/answer_search_service.dart';
import '../data/player.dart';
import '../data/player_database.dart';
import '../game/one_team/one_team_game.dart';
import '../game/xox/factor_art.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/brutalist_button.dart';
import '../widgets/brutalist_card.dart';
import '../widgets/states.dart';

/// **1 Team 1 Country** — a two-player party quiz.
///
/// Tapping "New Round" spins two slot boxes that land on a random club + a
/// random nationality (always a pair with a matching player). Players then name
/// footballers who turned out for that club AND hold that nationality; the
/// "Answers" button reveals the full list. A manual scoreboard tracks the two
/// players.
class OneTeamOneCountryScreen extends StatefulWidget {
  const OneTeamOneCountryScreen({super.key});

  @override
  State<OneTeamOneCountryScreen> createState() =>
      _OneTeamOneCountryScreenState();
}

class _OneTeamOneCountryScreenState extends State<OneTeamOneCountryScreen> {
  final Random _rng = Random();

  /// The game logic, built once the player corpus is loaded.
  late OneTeamGame _game;
  bool _loading = true;

  /// Fetches live reference answers; falls back to the local corpus.
  final AnswerSearchService _answerSearch = AnswerSearchService();

  /// The settled pair.
  late String _team;
  late String _country;

  /// The (possibly mid-spin) value shown in each box.
  late String _displayTeam;
  late String _displayCountry;

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
      debugPrint('[1T1C] Loaded ${corpus.length} players');
    } catch (e) {
      debugPrint('[1T1C] DB load failed: $e');
      corpus = const [];
    }
    if (!mounted) return;
    final game = OneTeamGame(corpus);
    final pair = game.randomPair(_rng);
    setState(() {
      _game = game;
      _team = _displayTeam = pair.team;
      _country = _displayCountry = pair.nationality;
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
    final teams = OneTeamGame.teams;
    final nations = OneTeamGame.nationalities;
    setState(() => _spinning = true);

    _spinTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      setState(() {
        _displayTeam = teams[_rng.nextInt(teams.length)];
        _displayCountry = nations[_rng.nextInt(nations.length)];
      });
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _spinTimer?.cancel();
      final pair = _game.randomPair(_rng);
      setState(() {
        _team = _displayTeam = pair.team;
        _country = _displayCountry = pair.nationality;
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
        _game.matchingPlayers(_team, _country).map((p) => p.name).toList();
    showDialog<void>(
      context: context,
      builder: (context) => _AnswersDialog(
        team: _team,
        country: _country,
        search: _answerSearch.search(condition1: _team, condition2: _country),
        fallback: fallback,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('1 TEAM 1 COUNTRY', style: AppTheme.heading(20)),
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
                      // ── Slot boxes: team + country ──
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: SuccessPop(
                                trigger: _spinning ? null : _team,
                                child: _SlotBox(
                                  label: _displayTeam,
                                  image: _TeamLogo(team: _displayTeam),
                                  spinning: _spinning,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: SuccessPop(
                                trigger: _spinning ? null : _country,
                                child: _SlotBox(
                                  label: _displayCountry,
                                  image: _CountryFlag(country: _displayCountry),
                                  spinning: _spinning,
                                ),
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
                        child: const Text('YENİ TUR'),
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

/// A slot box showing an [image] above a [label].
class _SlotBox extends StatelessWidget {
  const _SlotBox({
    required this.label,
    required this.image,
    required this.spinning,
  });

  final String label;
  final Widget image;
  final bool spinning;

  @override
  Widget build(BuildContext context) {
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
          SizedBox(height: 84, child: Center(child: image)),
          const SizedBox(height: AppSpacing.md),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.headline(),
          ),
        ],
      ),
    );
  }
}

/// A club logo, falling back to the club name when no asset is available.
class _TeamLogo extends StatelessWidget {
  const _TeamLogo({required this.team});

  final String team;

  @override
  Widget build(BuildContext context) {
    final asset = FactorArtResolver.teamLogoAsset(team);
    if (asset == null) return _fallback(team);
    return Image.asset(
      asset,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => _fallback(team),
    );
  }
}

/// A national flag, falling back to the country name when no URL is available.
class _CountryFlag extends StatelessWidget {
  const _CountryFlag({required this.country});

  final String country;

  @override
  Widget build(BuildContext context) {
    final url = FactorArtResolver.countryFlagUrl(country);
    if (url == null) return _fallback(country);
    return Image.network(
      url,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => _fallback(country),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.pitchGreen),
          ),
        );
      },
    );
  }
}

Widget _fallback(String text) {
  return Center(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTheme.heading(20, color: AppColors.pitchGreen),
      ),
    ),
  );
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

/// A scrollable popup listing footballers who played for the club and hold the
/// nationality.
///
/// While [search] is in flight it shows a loading state, then renders the live
/// LLM names; if the search yields `null` (no key / network / parse failure) it
/// falls back to the on-device [fallback] names.
class _AnswersDialog extends StatefulWidget {
  const _AnswersDialog({
    required this.team,
    required this.country,
    required this.search,
    required this.fallback,
  });

  final String team;
  final String country;
  final Future<AnswerResult?> search;
  final List<String> fallback;

  @override
  State<_AnswersDialog> createState() => _AnswersDialogState();
}

class _AnswersDialogState extends State<_AnswersDialog> {
  bool _loading = true;
  late List<String> _names;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  /// Whether the shown list was fact-checked. The local [fallback] corpus is
  /// trusted, so it counts as verified; only an unverified live result is false.
  bool _verified = true;

  @override
  void initState() {
    super.initState();
    _names = widget.fallback;
    _resolve();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    final live = await widget.search;
    if (!mounted) return;
    setState(() {
      _names = live?.players ?? widget.fallback;
      _verified = live?.verified ?? true;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final filteredNames = _names
        .where((n) => n.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

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
              '${widget.team}  ×  ${widget.country}',
              textAlign: TextAlign.center,
              style: AppTheme.headline(),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _loading ? 'ARANIYOR…' : '${_names.length} OYUNCU',
              textAlign: TextAlign.center,
              style: AppTheme.overline(color: AppColors.pitchGreen),
            ),
            if (!_loading && _names.isNotEmpty && !_verified) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '⚠ DOĞRULANMADI — KONTROL EDİLMEDİ',
                textAlign: TextAlign.center,
                style: AppTheme.overline(color: AppColors.danger),
              ),
            ],
            if (!_loading && _names.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: AppTheme.label(14),
                cursorColor: AppColors.pitchGreen,
                decoration: InputDecoration(
                  hintText: 'OYUNCU ARA...',
                  hintStyle: AppTheme.label(14, color: AppColors.whiteMuted),
                  prefixIcon: const Icon(Icons.search, color: AppColors.whiteMuted, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceLow,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    borderSide: const BorderSide(color: AppColors.pitchGreen, width: 2),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: _loading
                  ? const LoadingState(message: 'ARANIYOR…')
                  : filteredNames.isEmpty
                      ? const EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'EŞLEŞEN OYUNCU YOK',
                        )
                      : ListView.separated(
                          itemCount: filteredNames.length,
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
                                child: Text(filteredNames[i], style: AppTheme.body()),
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
