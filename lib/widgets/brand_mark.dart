import 'package:flutter/material.dart';

import '../theme/game_theme.dart';
import '../theme/tokens.dart';

/// App identity: a gold goal-tile glyph with the "2048" wordmark.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.compact = false});

  /// Glyph only (used where horizontal space is tight).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final g = context.gameTheme;
    final goal = g.tiles.of(2048);

    final glyph = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: goal.background,
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: goal.ring ?? goal.background, width: 2),
        boxShadow: [
          BoxShadow(
            color: goal.background.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      // The glyph is iconography, not reading text: keep it on one line.
      child: Text(
        '2048',
        maxLines: 1,
        textScaler: TextScaler.noScaling,
        style: GameTypography.tile(
          13,
          goal.foreground,
        ).copyWith(letterSpacing: -0.6),
      ),
    );

    if (compact) {
      return Semantics(label: '2048', header: true, child: glyph);
    }

    return Semantics(
      header: true,
      label: '2048 by Ndoto Labs',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          glyph,
          const SizedBox(width: Space.md),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '2048',
                style: GameTypography.title(
                  g.textPrimary,
                ).copyWith(height: 1.0),
              ),
              const SizedBox(height: 3),
              Text(
                'NDOTO LABS',
                style: GameTypography.label(g.textMuted).copyWith(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
