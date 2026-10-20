import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../theme/game_theme.dart';
import '../theme/tokens.dart';
import 'app_buttons.dart';

/// Themed confirmation dialog. Returns `true` when confirmed.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  IconData? icon,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final g = context.gameTheme;
      return Dialog(
        insetPadding: const EdgeInsets.all(Space.xxl),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.xxl,
            Space.xxl,
            Space.xxl,
            Space.lg,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: g.accentSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: g.accent, size: 24),
                  ),
                  const SizedBox(height: Space.lg),
                ],
                Text(title, style: GameTypography.title(g.textPrimary)),
                const SizedBox(height: Space.sm),
                Text(message, style: GameTypography.body(g.textSecondary)),
                const SizedBox(height: Space.xxl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: Space.sm),
                    PrimaryButton(
                      label: confirmLabel,
                      expand: false,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  return result ?? false;
}

/// Bottom sheet listing the four difficulties. Returns the chosen one or null.
Future<Difficulty?> showDifficultySheet(
  BuildContext context, {
  required Difficulty current,
}) {
  return showModalBottomSheet<Difficulty>(
    context: context,
    builder: (context) {
      final g = context.gameTheme;
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a board',
                style: GameTypography.title(g.textPrimary),
              ),
              const SizedBox(height: Space.xs),
              Text(
                'Bigger boards give longer games and higher scores.',
                style: GameTypography.body(g.textSecondary),
              ),
              const SizedBox(height: Space.lg),
              for (final d in Difficulty.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: _DifficultyRow(
                    difficulty: d,
                    selected: d == current,
                    onTap: () => Navigator.of(context).pop(d),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _DifficultyRow extends StatelessWidget {
  const _DifficultyRow({
    required this.difficulty,
    required this.selected,
    required this.onTap,
  });

  final Difficulty difficulty;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = context.gameTheme;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? g.accentSoft : g.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          side: BorderSide(color: selected ? g.accent : g.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.lg,
              vertical: Space.md,
            ),
            child: Row(
              children: [
                _GridGlyph(
                  size: difficulty.gridSize,
                  color: selected ? g.accent : g.textMuted,
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${difficulty.label}  ·  ${difficulty.gridLabel}',
                        style: GameTypography.bodyStrong(g.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        difficulty.description,
                        style: GameTypography.caption(g.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: Space.sm),
                  Icon(Icons.check_circle_rounded, color: g.accent, size: 22),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tiny N×N dot grid used as an icon for a board size.
class _GridGlyph extends StatelessWidget {
  const _GridGlyph({required this.size, required this.color});

  final int size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const box = 28.0;
    final n = size.clamp(2, 8);
    final gap = 2.0;
    final cell = (box - gap * (n - 1)) / n;
    return SizedBox(
      width: box,
      height: box,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (int r = 0; r < n; r++)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (int c = 0; c < n; c++)
                  Container(
                    width: cell,
                    height: cell,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(cell * 0.25),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
