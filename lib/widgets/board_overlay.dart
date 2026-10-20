import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../theme/game_theme.dart';
import '../theme/tokens.dart';
import 'app_buttons.dart';

/// Win / game-over panel rendered inside the board.
///
/// Purely declarative: visible whenever [GameState.status] is `won` or
/// `over`, so rebuilds can never re-trigger it. The "New record" ribbon is
/// shown only at the terminal (game over) state, which is where a record is
/// actually final; the win panel shows a compact chip instead.
class BoardOverlay extends StatelessWidget {
  const BoardOverlay({
    super.key,
    required this.state,
    required this.best,
    required this.onNewGame,
    required this.onChangeDifficulty,
    required this.onKeepGoing,
  });

  final GameState state;
  final int best;
  final VoidCallback onNewGame;
  final VoidCallback onChangeDifficulty;
  final VoidCallback onKeepGoing;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final visible = state.isOver || state.isWonPending;

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSwitcher(
        duration: motion.overlay,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(anim),
            child: child,
          ),
        ),
        child: !visible
            ? const SizedBox.shrink()
            : _Panel(
                key: ValueKey(state.isOver ? 'over' : 'won'),
                state: state,
                best: best,
                onNewGame: onNewGame,
                onChangeDifficulty: onChangeDifficulty,
                onKeepGoing: onKeepGoing,
              ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    super.key,
    required this.state,
    required this.best,
    required this.onNewGame,
    required this.onChangeDifficulty,
    required this.onKeepGoing,
  });

  final GameState state;
  final int best;
  final VoidCallback onNewGame;
  final VoidCallback onChangeDifficulty;
  final VoidCallback onKeepGoing;

  @override
  Widget build(BuildContext context) {
    final g = context.gameTheme;
    final isOver = state.isOver;
    final record = state.isNewRecord;

    final String title;
    final String subtitle;
    final IconData icon;
    final Color iconColor;
    if (isOver) {
      title = record ? 'New record!' : 'Game over';
      subtitle = record
          ? 'You beat your best on ${state.difficulty.label}.'
          : 'No moves left on the ${state.difficulty.gridLabel} board.';
      icon = record ? Icons.emoji_events_rounded : Icons.grid_off_rounded;
      iconColor = record ? g.accent : g.textSecondary;
    } else {
      title = 'You made 2048!';
      subtitle = 'Keep going for bigger tiles, or start fresh.';
      icon = Icons.celebration_rounded;
      iconColor = g.accent;
    }

    return Semantics(
      container: true,
      liveRegion: true,
      label: '$title. $subtitle Score ${state.score}, best $best.',
      child: ColoredBox(
        color: g.scrim,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 440;
            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(compact ? Space.md : Space.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: compact ? 40 : 56,
                        height: compact ? 40 : 56,
                        decoration: BoxDecoration(
                          color: record || !isOver
                              ? g.accentSoft
                              : g.surfaceRaised,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: iconColor,
                          size: compact ? 22 : 30,
                        ),
                      ),
                      SizedBox(height: compact ? Space.sm : Space.md),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: compact
                            ? GameTypography.title(g.textPrimary)
                            : GameTypography.display(
                                g.textPrimary,
                              ).copyWith(fontSize: 26),
                      ),
                      const SizedBox(height: Space.xs),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: GameTypography.body(g.textSecondary),
                      ),
                      SizedBox(height: compact ? Space.md : Space.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Stat(
                            label: 'SCORE',
                            value: state.score,
                            emphasize: true,
                            compact: compact,
                          ),
                          const SizedBox(width: Space.sm),
                          _Stat(
                            label: 'BEST',
                            value: best,
                            emphasize: false,
                            compact: compact,
                          ),
                        ],
                      ),
                      if (!isOver && record) ...[
                        const SizedBox(height: Space.md),
                        _RecordChip(),
                      ],
                      SizedBox(height: compact ? Space.md : Space.lg),
                      PrimaryButton(
                        label: isOver ? 'Play again' : 'Keep going',
                        icon: isOver
                            ? Icons.replay_rounded
                            : Icons.arrow_forward_rounded,
                        onPressed: isOver ? onNewGame : onKeepGoing,
                      ),
                      const SizedBox(height: Space.sm),
                      SecondaryButton(
                        label: isOver ? 'Change difficulty' : 'New game',
                        icon: isOver
                            ? Icons.tune_rounded
                            : Icons.refresh_rounded,
                        onPressed: isOver ? onChangeDifficulty : onNewGame,
                      ),
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

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.emphasize,
    required this.compact,
  });

  final String label;
  final int value;
  final bool emphasize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final g = context.gameTheme;
    return Container(
      constraints: BoxConstraints(minWidth: compact ? 96 : 108),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? Space.md : Space.lg,
        vertical: compact ? Space.sm : Space.md,
      ),
      decoration: BoxDecoration(
        color: g.surfaceRaised,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(
          color: emphasize ? g.accent.withValues(alpha: 0.5) : g.outline,
        ),
      ),
      child: Column(
        children: [
          Text(label, style: GameTypography.label(g.textMuted)),
          const SizedBox(height: Space.xs),
          Text(
            '$value',
            style: GameTypography.scoreLarge(
              emphasize ? g.accent : g.textPrimary,
            ).copyWith(fontSize: compact ? 20 : 24),
          ),
        ],
      ),
    );
  }
}

class _RecordChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final g = context.gameTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 6),
      decoration: BoxDecoration(
        color: g.accentSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_rounded, size: 16, color: g.accent),
          const SizedBox(width: 6),
          Text('New best so far', style: GameTypography.caption(g.accent)),
        ],
      ),
    );
  }
}
