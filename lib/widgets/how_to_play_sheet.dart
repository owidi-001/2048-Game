import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../models/tile.dart';
import '../theme/game_theme.dart';
import '../theme/tokens.dart';
import 'app_buttons.dart';
import 'tile_widget.dart';

/// "How to play" bottom sheet: the four mechanics in plain language plus a
/// live tile demo built from the real [TileWidget].
Future<void> showHowToPlaySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _HowToPlaySheet(),
  );
}

class _HowToPlaySheet extends StatelessWidget {
  const _HowToPlaySheet();

  @override
  Widget build(BuildContext context) {
    final g = context.gameTheme;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How to play', style: GameTypography.title(g.textPrimary)),
              const SizedBox(height: Space.xs),
              Text(
                'Slide, match, and double your way to 2048.',
                style: GameTypography.body(g.textSecondary),
              ),
              const SizedBox(height: Space.xl),
              const _MergeDemo(),
              const SizedBox(height: Space.xl),
              const _Step(
                icon: Icons.swipe_rounded,
                title: 'Swipe to slide',
                text:
                    'Swipe up, down, left or right. Every tile slides as far as it can in that direction.',
              ),
              const _Step(
                icon: Icons.join_full_rounded,
                title: 'Match to merge',
                text:
                    'Two tiles with the same number that touch become one tile with double the value.',
              ),
              const _Step(
                icon: Icons.stars_rounded,
                title: 'Score as you merge',
                text:
                    'Each merge adds the new tile\'s value to your score. Build a 2048 tile to win, then keep going for more.',
              ),
              const _Step(
                icon: Icons.grid_view_rounded,
                title: 'Pick your board',
                text:
                    'Easy 4×4 is the classic. Medium 5×5, Hard 6×6 and Expert 8×8 give you more room, longer games and bigger scores. Each board keeps its own best.',
              ),
              const _Step(
                icon: Icons.undo_rounded,
                title: 'Undo a slip',
                text:
                    'Undo reverses your last move, up to ten moves back. The game ends when no slides or merges remain.',
                last: true,
              ),
              const SizedBox(height: Space.xl),
              PrimaryButton(
                label: 'Got it',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.icon,
    required this.title,
    required this.text,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final g = context.gameTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : Space.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: g.accentSoft,
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: Icon(icon, color: g.accent, size: 22),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GameTypography.heading(g.textPrimary)),
                const SizedBox(height: 3),
                Text(text, style: GameTypography.body(g.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// [2][2] → [4] rendered with real tiles.
class _MergeDemo extends StatelessWidget {
  const _MergeDemo();

  @override
  Widget build(BuildContext context) {
    final g = context.gameTheme;
    const cell = 44.0;
    Widget tile(int id, int value) => SizedBox(
      width: cell,
      height: cell,
      child: TileWidget(
        tile: Tile(id: id, value: value, row: 0, col: 0),
        cellSize: cell,
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.md,
      ),
      decoration: BoxDecoration(
        color: g.board,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: g.boardOutline),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            tile(1, 2),
            const SizedBox(width: Space.sm),
            tile(2, 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.md),
              child: Icon(Icons.arrow_forward_rounded, color: g.textMuted),
            ),
            tile(3, 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.md),
              child: Text('…', style: GameTypography.heading(g.textMuted)),
            ),
            tile(4, 1024),
            const SizedBox(width: Space.sm),
            tile(5, 1024),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.md),
              child: Icon(Icons.arrow_forward_rounded, color: g.textMuted),
            ),
            tile(6, 2048),
          ],
        ),
      ),
    );
  }
}

/// Exposed for tests: the difficulties described in the sheet.
List<Difficulty> howToPlayDifficulties() => Difficulty.values;
