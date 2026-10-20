import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../theme/game_theme.dart';
import '../theme/tokens.dart';

/// Quiet one-line summary under the board: highest tile and move count.
class StatusStrip extends StatelessWidget {
  const StatusStrip({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final g = context.gameTheme;
    final highest = state.highestTile;
    final tile = g.tiles.of(highest);

    return Semantics(
      label: 'Highest tile $highest. ${state.moves} moves.',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (highest > 0) ...[
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tile.background,
                  borderRadius: BorderRadius.circular(5),
                  border: tile.ring != null
                      ? Border.all(color: tile.ring!, width: 1.5)
                      : null,
                ),
                child: FittedBox(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      '$highest',
                      style: GameTypography.tile(10, tile.foreground),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Space.sm),
              Text('Highest tile', style: GameTypography.caption(g.textMuted)),
              const SizedBox(width: 4),
              Text(
                '$highest',
                style: GameTypography.caption(
                  g.textSecondary,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              _Dot(color: g.textMuted),
            ],
            Icon(Icons.swipe_rounded, size: 16, color: g.textMuted),
            const SizedBox(width: 6),
            Text(
              '${state.moves} ${state.moves == 1 ? 'move' : 'moves'}',
              style: GameTypography.caption(
                g.textSecondary,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.md),
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
