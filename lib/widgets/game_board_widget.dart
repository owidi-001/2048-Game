import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../models/tile.dart';
import '../providers/game_provider.dart';
import '../services/game_engine.dart';
import '../theme/game_theme.dart';
import '../theme/tokens.dart';
import '../utils/constants.dart';
import 'board_overlay.dart';
import 'swipe_detector.dart';
import 'tile_widget.dart';

/// The playing surface: grid, animated tiles, swipe input, invalid-move nudge
/// and the integrated win / game-over overlay.
///
/// Sizes itself to the largest square that fits the incoming constraints
/// (capped at [Layout.maxBoardSize]).
class GameBoardWidget extends StatefulWidget {
  const GameBoardWidget({
    super.key,
    required this.onNewGame,
    required this.onChangeDifficulty,
    required this.onKeepGoing,
  });

  final VoidCallback onNewGame;
  final VoidCallback onChangeDifficulty;
  final VoidCallback onKeepGoing;

  @override
  State<GameBoardWidget> createState() => _GameBoardWidgetState();
}

class _GameBoardWidgetState extends State<GameBoardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _nudge = AnimationController(vsync: this);
  Offset _nudgeDirection = Offset.zero;
  int _seenInvalidTick = 0;

  @override
  void dispose() {
    _nudge.dispose();
    super.dispose();
  }

  void _maybeNudge(GameProvider provider) {
    if (provider.invalidTick == _seenInvalidTick) return;
    _seenInvalidTick = provider.invalidTick;
    final motion = Motion.of(context);
    if (motion.nudge == Duration.zero) return;
    _nudgeDirection = switch (provider.lastInvalidDirection) {
      Direction.left => const Offset(-1, 0),
      Direction.right => const Offset(1, 0),
      Direction.up => const Offset(0, -1),
      Direction.down => const Offset(0, 1),
      null => Offset.zero,
    };
    _nudge
      ..duration = motion.nudge
      ..forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    _maybeNudge(provider);
    final state = provider.state;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : Layout.maxBoardSize;
        final maxH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : Layout.maxBoardSize;
        final boardSize = [
          maxW,
          maxH,
          Layout.maxBoardSize,
        ].reduce((a, b) => a < b ? a : b);
        if (boardSize <= 0) return const SizedBox.shrink();

        return Center(
          child: SizedBox(
            width: boardSize,
            height: boardSize,
            child: Semantics(
              label:
                  'Game board, ${state.difficulty.gridLabel}, '
                  'score ${state.score}, highest tile ${state.highestTile}. '
                  'Swipe or use arrow keys to move tiles.',
              child: SwipeDetector(
                enabled: !state.isOver && !state.isWonPending,
                onSwipe: provider.move,
                child: AnimatedBuilder(
                  animation: _nudge,
                  builder: (context, child) {
                    // Quick out-and-back shove of ~6px toward the rejected direction.
                    final t = _nudge.value;
                    final amount = t < 0.5 ? t * 2 : (1 - t) * 2;
                    return Transform.translate(
                      offset:
                          _nudgeDirection *
                          (6 * Curves.easeOut.transform(amount)),
                      child: child,
                    );
                  },
                  child: _BoardSurface(
                    boardSize: boardSize,
                    state: state,
                    isNewRecord: state.isNewRecord,
                    best: provider.currentBest,
                    onNewGame: widget.onNewGame,
                    onChangeDifficulty: widget.onChangeDifficulty,
                    onKeepGoing: widget.onKeepGoing,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BoardSurface extends StatelessWidget {
  const _BoardSurface({
    required this.boardSize,
    required this.state,
    required this.isNewRecord,
    required this.best,
    required this.onNewGame,
    required this.onChangeDifficulty,
    required this.onKeepGoing,
  });

  final double boardSize;
  final GameState state;
  final bool isNewRecord;
  final int best;
  final VoidCallback onNewGame;
  final VoidCallback onChangeDifficulty;
  final VoidCallback onKeepGoing;

  @override
  Widget build(BuildContext context) {
    final g = context.gameTheme;
    final motion = Motion.of(context);
    final size = state.difficulty.gridSize;
    final gap = boardGap(size);
    final pad = boardPadding(size);
    final cellSize = (boardSize - pad * 2 - gap * (size - 1)) / size;
    final boardRadius = (boardSize * 0.045).clamp(Radii.md, Radii.xl);

    double left(int col) => pad + col * (cellSize + gap);
    double top(int row) => pad + row * (cellSize + gap);

    // Absorbed tiles render behind active tiles so they slide under the merge result.
    final absorbed = state.tiles.where((t) => t.isAbsorbed);
    final active = state.tiles.where((t) => !t.isAbsorbed);

    Widget positioned(Tile tile) => AnimatedPositioned(
      key: ValueKey(tile.id),
      duration: motion.tileSlide,
      curve: Motion.slide,
      left: left(tile.col),
      top: top(tile.row),
      width: cellSize,
      height: cellSize,
      child: TileWidget(tile: tile, cellSize: cellSize),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: g.board,
        borderRadius: BorderRadius.circular(boardRadius),
        border: Border.all(color: g.boardOutline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(boardRadius),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (int r = 0; r < size; r++)
              for (int c = 0; c < size; c++)
                Positioned(
                  left: left(c),
                  top: top(r),
                  width: cellSize,
                  height: cellSize,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: g.emptyCell,
                      borderRadius: BorderRadius.circular(tileRadius(cellSize)),
                    ),
                  ),
                ),
            for (final tile in absorbed) positioned(tile),
            for (final tile in active) positioned(tile),
            Positioned.fill(
              child: BoardOverlay(
                state: state,
                best: best,
                onNewGame: onNewGame,
                onChangeDifficulty: onChangeDifficulty,
                onKeepGoing: onKeepGoing,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
