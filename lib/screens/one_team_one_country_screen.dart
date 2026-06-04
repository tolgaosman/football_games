import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/player.dart';
import '../game/one_team/one_team_game.dart';
import '../game/xox/factor_art.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/brutalist_button.dart';
import '../widgets/brutalist_card.dart';

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
    final pair = OneTeamGame.randomPair(_rng);
    _team = _displayTeam = pair.team;
    _country = _displayCountry = pair.nationality;
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
      final pair = OneTeamGame.randomPair(_rng);
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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          side: const BorderSide(color: AppColors.white, width: AppTheme.borderWidth),
        ),
        title: Text('İSİM', style: AppTheme.heading(20)),
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
    final players = OneTeamGame.matchingPlayers(_team, _country);
    showDialog<void>(
      context: context,
      builder: (context) => _AnswersDialog(
        team: _team,
        country: _country,
        players: players,
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      // ── Slot boxes: team + country ──
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _SlotBox(
                                label: _displayTeam,
                                image: _TeamLogo(team: _displayTeam),
                                spinning: _spinning,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _SlotBox(
                                label: _displayCountry,
                                image: _CountryFlag(country: _displayCountry),
                                spinning: _spinning,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
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
                            const SizedBox(width: 14),
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
                      const SizedBox(height: 32),
                      // ── Action buttons ──
                      BrutalistButton(
                        onPressed: _spinning ? null : _spin,
                        child: const Text('YENİ TUR'),
                      ),
                      const SizedBox(height: 14),
                      BrutalistButton(
                        onPressed: _spinning ? null : _showAnswers,
                        color: AppColors.surface,
                        foregroundColor: AppColors.white,
                        borderColor: AppColors.pitchGreen,
                        child: const Text('CEVAPLAR'),
                      ),
                      const SizedBox(height: 12),
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
      borderColor: spinning ? AppColors.pitchGreen : AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 84, child: Center(child: image)),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.heading(16),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                    style: AppTheme.label(14, color: AppColors.whiteMuted),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.edit, size: 14, color: AppColors.whiteMuted),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('$score', style: AppTheme.heading(44, color: AppColors.pitchGreen)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: BrutalistButton(
                  onPressed: onDecrement,
                  color: AppColors.surfaceLow,
                  foregroundColor: AppColors.white,
                  borderColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  restingOffset: const Offset(3, 3),
                  child: const Text('−'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BrutalistButton(
                  onPressed: onIncrement,
                  padding: const EdgeInsets.symmetric(vertical: 10),
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

/// A scrollable popup listing every footballer who played for the club and
/// holds the nationality.
class _AnswersDialog extends StatelessWidget {
  const _AnswersDialog({
    required this.team,
    required this.country,
    required this.players,
  });

  final String team;
  final String country;
  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: BrutalistCard(
        borderColor: AppColors.pitchGreen,
        padding: const EdgeInsets.all(18),
        height: size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$team  ×  $country',
              textAlign: TextAlign.center,
              style: AppTheme.heading(18),
            ),
            const SizedBox(height: 4),
            Text(
              '${players.length} OYUNCU',
              textAlign: TextAlign.center,
              style: AppTheme.label(12, color: AppColors.pitchGreen),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: players.isEmpty
                  ? Center(
                      child: Text(
                        'Eşleşen oyuncu yok',
                        style: AppTheme.label(16, color: AppColors.whiteMuted),
                      ),
                    )
                  : ListView.separated(
                      itemCount: players.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final p = players[i];
                        return BrutalistCard(
                          color: AppColors.surfaceLow,
                          borderColor: AppColors.white,
                          shadowOffset: Offset.zero,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Text(p.name, style: AppTheme.label(16)),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 14),
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
