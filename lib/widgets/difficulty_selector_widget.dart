import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../theme/game_theme.dart';
import '../theme/tokens.dart';

/// Segmented control for the four board sizes.
///
/// One container, four equal segments, and a single sliding accent indicator
/// so the selected state is unmistakable. Each segment shows the difficulty
/// name and its grid size and is at least 52 px tall.
class DifficultySelectorWidget extends StatelessWidget {
  const DifficultySelectorWidget({
    super.key,
    required this.current,
    required this.onChanged,
    this.vertical = false,
  });

  final Difficulty current;
  final ValueChanged<Difficulty> onChanged;

  /// Stacked list variant for the wide sidebar layout.
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    if (vertical) return _VerticalList(current: current, onChanged: onChanged);
    return _Segmented(current: current, onChanged: onChanged);
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.current, required this.onChanged});

  final Difficulty current;
  final ValueChanged<Difficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    final g = context.gameTheme;
    final motion = Motion.of(context);
    const pad = 4.0;
    final count = Difficulty.values.length;
    final index = Difficulty.values.indexOf(current);

    return Semantics(
      container: true,
      label: 'Difficulty',
      child: Container(
        height: 56,
        padding: const EdgeInsets.all(pad),
        decoration: BoxDecoration(
          color: g.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: g.outline),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final segW = constraints.maxWidth / count;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: motion.ui,
                  curve: Motion.uiCurve,
                  left: segW * index,
                  top: 0,
                  bottom: 0,
                  width: segW,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: g.accent,
                      borderRadius: BorderRadius.circular(Radii.lg - pad),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (final d in Difficulty.values)
                      Expanded(
                        child: _Segment(
                          difficulty: d,
                          selected: d == current,
                          onTap: () => onChanged(d),
                          duration: motion.ui,
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.difficulty,
    required this.selected,
    required this.onTap,
    required this.duration,
  });

  final Difficulty difficulty;
  final bool selected;
  final VoidCallback onTap;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final g = context.gameTheme;
    final fg = selected ? g.onAccent : g.textSecondary;
    final fgSoft = selected ? g.onAccent.withValues(alpha: 0.72) : g.textMuted;

    return Semantics(
      button: true,
      selected: selected,
      label: '${difficulty.label}, ${difficulty.gridLabel}',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.lg - 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.lg - 4),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: duration,
                    style: GameTypography.bodyStrong(
                      fg,
                    ).copyWith(fontSize: 13, height: 1.0),
                    child: Text(difficulty.label),
                  ),
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: duration,
                    style: GameTypography.caption(
                      fgSoft,
                    ).copyWith(fontSize: 11, height: 1.0),
                    child: Text(difficulty.gridLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VerticalList extends StatelessWidget {
  const _VerticalList({required this.current, required this.onChanged});

  final Difficulty current;
  final ValueChanged<Difficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    final g = context.gameTheme;
    final motion = Motion.of(context);
    return Column(
      children: [
        for (final d in Difficulty.values)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: Semantics(
              button: true,
              selected: d == current,
              label: '${d.label}, ${d.gridLabel}',
              child: Material(
                color: d == current ? g.accent : g.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.md),
                  side: BorderSide(color: d == current ? g.accent : g.outline),
                ),
                clipBehavior: Clip.antiAlias,
                animationDuration: motion.ui,
                child: InkWell(
                  onTap: () => onChanged(d),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.lg,
                      vertical: Space.md,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            d.label,
                            style: GameTypography.bodyStrong(
                              d == current ? g.onAccent : g.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          d.gridLabel,
                          style: GameTypography.caption(
                            d == current
                                ? g.onAccent.withValues(alpha: 0.75)
                                : g.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
