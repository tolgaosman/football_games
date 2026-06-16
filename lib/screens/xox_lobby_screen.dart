import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/brutalist_button.dart';
import '../widgets/brutalist_card.dart';

/// Pre-game lobby for Football XOX: both players enter their names, and
/// X / O marks are assigned randomly. Returns a [XoxLobbyResult] to the
/// calling route so the game screen knows who is who.
class XoxLobbyScreen extends StatefulWidget {
  const XoxLobbyScreen({super.key});

  @override
  State<XoxLobbyScreen> createState() => _XoxLobbyScreenState();
}

/// The result passed back from the lobby to the game screen.
class XoxLobbyResult {
  const XoxLobbyResult({
    required this.playerXName,
    required this.playerOName,
  });

  /// Name of the player who will play as X.
  final String playerXName;

  /// Name of the player who will play as O.
  final String playerOName;
}

class _XoxLobbyScreenState extends State<XoxLobbyScreen>
    with SingleTickerProviderStateMixin {
  final _player1Controller = TextEditingController();
  final _player2Controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _player1Focus = FocusNode();
  final _player2Focus = FocusNode();

  /// True once the user taps START; triggers the coin-flip animation before
  /// navigating to the game.
  bool _flipping = false;

  /// Resolved after the coin flip.
  XoxLobbyResult? _result;

  @override
  void dispose() {
    _player1Controller.dispose();
    _player2Controller.dispose();
    _player1Focus.dispose();
    _player2Focus.dispose();
    super.dispose();
  }

  void _onStart() {
    if (!_formKey.currentState!.validate()) return;
    _player1Focus.unfocus();
    _player2Focus.unfocus();

    final name1 = _player1Controller.text.trim();
    final name2 = _player2Controller.text.trim();

    // Coin flip: randomly decide who gets X (goes first).
    final firstIsX = Random().nextBool();
    final result = XoxLobbyResult(
      playerXName: firstIsX ? name1 : name2,
      playerOName: firstIsX ? name2 : name1,
    );

    setState(() {
      _flipping = true;
      _result = result;
    });

    // Show the assignment for a moment, then navigate.
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FOOTBALL XOX')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xl,
            ),
            child: _flipping ? _buildFlipResult() : _buildForm(),
          ),
        ),
      ),
    );
  }

  // ---- Name entry form -----------------------------------------------------

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeSlideIn(
            child: Icon(
              Icons.grid_3x3_rounded,
              size: 64,
              color: AppColors.pitchGreen.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FadeSlideIn(
            delay: const Duration(milliseconds: 60),
            child: Text('ENTER PLAYER NAMES',
                style: AppTheme.headline(color: AppColors.white)),
          ),
          const SizedBox(height: AppSpacing.sm),
          FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: Text(
              'X and O will be assigned randomly',
              style: AppTheme.caption(),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Player 1
          FadeSlideIn(
            delay: const Duration(milliseconds: 180),
            child: _NameField(
              controller: _player1Controller,
              focusNode: _player1Focus,
              label: 'PLAYER 1',
              icon: Icons.person_rounded,
              onSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_player2Focus),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Player 2
          FadeSlideIn(
            delay: const Duration(milliseconds: 260),
            child: _NameField(
              controller: _player2Controller,
              focusNode: _player2Focus,
              label: 'PLAYER 2',
              icon: Icons.person_outline_rounded,
              onSubmitted: (_) => _onStart(),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Start button
          FadeSlideIn(
            delay: const Duration(milliseconds: 340),
            child: BrutalistButton(
              onPressed: _onStart,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl, vertical: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded, size: 28),
                  const SizedBox(width: AppSpacing.md),
                  Text('START MATCH',
                      style: AppTheme.heading(22, color: AppColors.black)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Coin-flip reveal ----------------------------------------------------

  Widget _buildFlipResult() {
    final r = _result!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeSlideIn(
          child: Text('⚡', style: TextStyle(fontSize: 56)),
        ),
        const SizedBox(height: AppSpacing.xl),
        FadeSlideIn(
          delay: const Duration(milliseconds: 200),
          child: Text('THE DRAW IS MADE!',
              style: AppTheme.display(color: AppColors.pitchGreen)),
        ),
        const SizedBox(height: AppSpacing.xxl),
        FadeSlideIn(
          delay: const Duration(milliseconds: 500),
          child: _AssignmentChip(
            name: r.playerXName,
            mark: 'X',
            color: AppColors.pitchGreen,
            subtitle: 'GOES FIRST',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FadeSlideIn(
          delay: const Duration(milliseconds: 700),
          child: _AssignmentChip(
            name: r.playerOName,
            mark: 'O',
            color: AppColors.white,
            subtitle: 'GOES SECOND',
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        FadeSlideIn(
          delay: const Duration(milliseconds: 1000),
          child: Text(
            'GET READY...',
            style: AppTheme.overline(color: AppColors.pitchGreen),
          ),
        ),
      ],
    );
  }
}

// ---- Private helper widgets ------------------------------------------------

/// A styled text field for entering a player name.
class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.icon,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final IconData icon;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return BrutalistCard(
      color: AppColors.surface,
      borderColor: AppColors.border,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        textCapitalization: TextCapitalization.words,
        style: AppTheme.headline(color: AppColors.white),
        textInputAction: TextInputAction.next,
        onFieldSubmitted: onSubmitted,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: label,
          hintStyle: AppTheme.headline(color: AppColors.whiteMuted.withValues(alpha: 0.4)),
          icon: Icon(icon, color: AppColors.pitchGreen, size: 28),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter a name';
          }
          return null;
        },
      ),
    );
  }
}

/// A card showing a player's mark assignment with a subtle pop effect.
class _AssignmentChip extends StatelessWidget {
  const _AssignmentChip({
    required this.name,
    required this.mark,
    required this.color,
    required this.subtitle,
  });

  final String name;
  final String mark;
  final Color color;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return BrutalistCard(
      color: AppColors.surface,
      borderColor: color,
      shadowOffset: const Offset(5, 5),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      child: Row(
        children: [
          // Mark badge
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(color: color, width: 3),
            ),
            child: Text(
              mark,
              style: AppTheme.display(color: color),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.headline(color: AppColors.white),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTheme.overline(color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
