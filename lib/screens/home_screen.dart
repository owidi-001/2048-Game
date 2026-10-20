import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../theme/game_theme.dart';
import '../theme/tokens.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/brand_mark.dart';
import '../widgets/difficulty_selector_widget.dart';
import '../widgets/game_board_widget.dart';
import '../widgets/how_to_play_sheet.dart';
import '../widgets/score_panel.dart';
import '../widgets/status_strip.dart';

/// The single game screen. Composes the header, difficulty selector, board
/// and action bar, and owns user-flow decisions (confirmations, sheets).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GameProvider? _provider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<GameProvider>();
    if (!identical(provider, _provider)) {
      _provider?.removeListener(_onProviderChange);
      _provider = provider..addListener(_onProviderChange);
    }
  }

  @override
  void dispose() {
    _provider?.removeListener(_onProviderChange);
    super.dispose();
  }

  /// Side-effects only (haptics). All visual state is declarative.
  void _onProviderChange() {
    final provider = _provider;
    if (provider == null || !mounted) return;
    for (final effect in provider.takeEffects()) {
      switch (effect) {
        case GameEffect.merge:
          HapticFeedback.lightImpact();
        case GameEffect.invalidMove:
          HapticFeedback.selectionClick();
        case GameEffect.won:
          HapticFeedback.heavyImpact();
        case GameEffect.over:
          HapticFeedback.mediumImpact();
        case GameEffect.undo:
          HapticFeedback.selectionClick();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // User flows
  // ---------------------------------------------------------------------------

  Future<void> _newGame() async {
    final provider = context.read<GameProvider>();
    final state = provider.state;
    // A fresh or finished board can be reset without asking.
    if (state.hasProgress && !state.isOver) {
      final ok = await showConfirmDialog(
        context,
        icon: Icons.refresh_rounded,
        title: 'Start a new game?',
        message:
            'Your current ${state.difficulty.gridLabel} game and its score of '
            '${state.score} will be lost.',
        confirmLabel: 'New game',
      );
      if (!ok || !mounted) return;
    }
    await provider.newGame();
  }

  Future<void> _changeDifficulty(Difficulty target) async {
    final provider = context.read<GameProvider>();
    final state = provider.state;
    if (target == state.difficulty) return;
    if (state.hasProgress && !state.isOver) {
      final ok = await showConfirmDialog(
        context,
        icon: Icons.tune_rounded,
        title: 'Switch to ${target.label}?',
        message:
            'Changing to the ${target.gridLabel} board starts a new game. '
            'Your current score of ${state.score} will be lost.',
        confirmLabel: 'Switch',
      );
      if (!ok || !mounted) return;
    }
    await provider.newGame(difficulty: target);
  }

  Future<void> _pickDifficulty() async {
    final provider = context.read<GameProvider>();
    final chosen = await showDifficultySheet(
      context,
      current: provider.state.difficulty,
    );
    if (chosen == null || !mounted) return;
    if (chosen == provider.state.difficulty) {
      await provider.newGame();
    } else {
      await _changeDifficulty(chosen);
    }
  }

  void _keepGoing() => context.read<GameProvider>().continueAfterWin();

  void _undo() => context.read<GameProvider>().undo();

  void _howToPlay() => showHowToPlaySheet(context);

  @override
  Widget build(BuildContext context) {
    final g = context.gameTheme;
    return Scaffold(
      backgroundColor: g.background,
      body: MediaQuery.withClampedTextScaling(
        maxScaleFactor: Layout.maxTextScale,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide =
                  constraints.maxWidth >= Layout.wideBreakpoint &&
                  constraints.maxWidth > constraints.maxHeight;
              final board = GameBoardWidget(
                onNewGame: _newGame,
                onChangeDifficulty: _pickDifficulty,
                onKeepGoing: _keepGoing,
              );
              return wide
                  ? _WideLayout(
                      board: board,
                      onNewGame: _newGame,
                      onUndo: _undo,
                      onHowToPlay: _howToPlay,
                      onDifficulty: _changeDifficulty,
                    )
                  : _PortraitLayout(
                      board: board,
                      onNewGame: _newGame,
                      onUndo: _undo,
                      onHowToPlay: _howToPlay,
                      onDifficulty: _changeDifficulty,
                    );
            },
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Layouts
// -----------------------------------------------------------------------------

class _PortraitLayout extends StatelessWidget {
  const _PortraitLayout({
    required this.board,
    required this.onNewGame,
    required this.onUndo,
    required this.onHowToPlay,
    required this.onDifficulty,
  });

  final Widget board;
  final VoidCallback onNewGame;
  final VoidCallback onUndo;
  final VoidCallback onHowToPlay;
  final ValueChanged<Difficulty> onDifficulty;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final state = provider.state;
    final compactHeight = MediaQuery.sizeOf(context).height < 700;
    final hPad = compactHeight ? Space.md : Space.lg;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Layout.maxContentWidth),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                hPad,
                compactHeight ? Space.sm : Space.md,
                hPad,
                0,
              ),
              child: _Header(provider: provider, compact: compactHeight),
            ),
            SizedBox(height: compactHeight ? Space.md : Space.lg),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: DifficultySelectorWidget(
                current: state.difficulty,
                onChanged: onDifficulty,
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: hPad,
                  vertical: compactHeight ? Space.md : Space.lg,
                ),
                child: _BoardArea(board: board, state: state),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                hPad,
                0,
                hPad,
                compactHeight ? Space.sm : Space.md,
              ),
              child: _ActionBar(
                provider: provider,
                onNewGame: onNewGame,
                onUndo: onUndo,
                onHowToPlay: onHowToPlay,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Board plus the status strip, sized together so the strip sits directly
/// under the board and never steals space from it on short screens.
class _BoardArea extends StatelessWidget {
  const _BoardArea({required this.board, required this.state});

  final Widget board;
  final GameState state;

  static const _stripHeight = 22.0;
  static const _stripGap = Space.md;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        // Show the strip only when there is room under a full-width board.
        final showStrip = h - w >= _stripHeight + _stripGap + Space.sm;
        final boardSide = [
          w,
          showStrip ? h - _stripHeight - _stripGap : h,
          Layout.maxBoardSize,
        ].reduce((a, b) => a < b ? a : b);

        return Align(
          // Slightly above centre: whitespace reads better under the board
          // than between the selector and the board.
          alignment: const Alignment(0, -0.4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: boardSide, height: boardSide, child: board),
              if (showStrip) ...[
                const SizedBox(height: _stripGap),
                SizedBox(
                  height: _stripHeight,
                  child: StatusStrip(state: state),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.board,
    required this.onNewGame,
    required this.onUndo,
    required this.onHowToPlay,
    required this.onDifficulty,
  });

  final Widget board;
  final VoidCallback onNewGame;
  final VoidCallback onUndo;
  final VoidCallback onHowToPlay;
  final ValueChanged<Difficulty> onDifficulty;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final g = context.gameTheme;
    final state = provider.state;
    // Phone-landscape heights get a denser sidebar; tablets get the full list.
    final short = MediaQuery.sizeOf(context).height < 560;
    final pad = short ? Space.lg : Space.xxl;

    final sidebar = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (short)
          Row(
            children: [
              const BrandMark(compact: true),
              const Spacer(),
              ScorePanel(
                score: state.score,
                best: provider.currentBest,
                isBeatingRecord: provider.isBeatingRecord,
                gainTick: provider.gainTick,
                lastGain: provider.lastGain,
              ),
            ],
          )
        else ...[
          const Align(alignment: Alignment.centerLeft, child: BrandMark()),
          const SizedBox(height: Space.xxl),
          ScorePanel(
            score: state.score,
            best: provider.currentBest,
            isBeatingRecord: provider.isBeatingRecord,
            gainTick: provider.gainTick,
            lastGain: provider.lastGain,
            vertical: true,
          ),
        ],
        SizedBox(height: short ? Space.lg : Space.xxl),
        if (!short) ...[
          Text('DIFFICULTY', style: GameTypography.label(g.textMuted)),
          const SizedBox(height: Space.sm),
        ],
        DifficultySelectorWidget(
          current: state.difficulty,
          onChanged: onDifficulty,
          vertical: !short,
        ),
        SizedBox(height: short ? Space.lg : Space.md),
        if (short)
          _ActionBar(
            provider: provider,
            onNewGame: onNewGame,
            onUndo: onUndo,
            onHowToPlay: onHowToPlay,
          )
        else ...[
          ActionButton(
            icon: Icons.refresh_rounded,
            label: 'New game',
            emphasis: true,
            horizontal: true,
            onPressed: onNewGame,
          ),
          const SizedBox(height: Space.sm),
          ActionButton(
            icon: Icons.undo_rounded,
            label: 'Undo',
            horizontal: true,
            badge: provider.undoDepth,
            onPressed: provider.canUndo ? onUndo : null,
          ),
          const SizedBox(height: Space.sm),
          ActionButton(
            icon: Icons.help_outline_rounded,
            label: 'How to play',
            horizontal: true,
            onPressed: onHowToPlay,
          ),
          const SizedBox(height: Space.lg),
          StatusStrip(state: state),
        ],
      ],
    );

    return Row(
      children: [
        SizedBox(
          width: short ? 340 : 320,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(pad),
            child: sidebar,
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(0, pad, pad, pad),
            child: board,
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Pieces
// -----------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.provider, required this.compact});

  final GameProvider provider;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final state = provider.state;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: BrandMark(compact: compact),
            ),
          ),
        ),
        const SizedBox(width: Space.md),
        ScorePanel(
          score: state.score,
          best: provider.currentBest,
          isBeatingRecord: provider.isBeatingRecord,
          gainTick: provider.gainTick,
          lastGain: provider.lastGain,
        ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.provider,
    required this.onNewGame,
    required this.onUndo,
    required this.onHowToPlay,
  });

  final GameProvider provider;
  final VoidCallback onNewGame;
  final VoidCallback onUndo;
  final VoidCallback onHowToPlay;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ActionButton(
            icon: Icons.refresh_rounded,
            label: 'New game',
            emphasis: true,
            onPressed: onNewGame,
          ),
        ),
        const SizedBox(width: Space.sm),
        Expanded(
          child: ActionButton(
            icon: Icons.undo_rounded,
            label: 'Undo',
            badge: provider.undoDepth,
            onPressed: provider.canUndo ? onUndo : null,
          ),
        ),
        const SizedBox(width: Space.sm),
        Expanded(
          child: ActionButton(
            icon: Icons.help_outline_rounded,
            label: 'How to play',
            onPressed: onHowToPlay,
          ),
        ),
      ],
    );
  }
}
