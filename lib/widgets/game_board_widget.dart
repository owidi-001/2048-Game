import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../services/game_engine.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import 'tile_widget.dart';

class GameBoardWidget extends StatelessWidget {
  const GameBoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKey(context),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v.abs() < kSwipeVelocityThreshold) return;
          context.read<GameProvider>().move(
                v > 0 ? Direction.right : Direction.left,
              );
        },
        onVerticalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v.abs() < kSwipeVelocityThreshold) return;
          context.read<GameProvider>().move(
                v > 0 ? Direction.down : Direction.up,
              );
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final boardSize = constraints.maxWidth.clamp(0.0, kMaxBoardWidth);
            return Center(
              child: SizedBox(
                width: boardSize,
                height: boardSize,
                child: _Board(boardSize: boardSize),
              ),
            );
          },
        ),
      ),
    );
  }

  KeyEventResult Function(FocusNode, KeyEvent) _handleKey(BuildContext context) {
    return (node, event) {
      if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
        return KeyEventResult.ignored;
      }
      final provider = context.read<GameProvider>();
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
        case LogicalKeyboardKey.keyA:
          provider.move(Direction.left);
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowRight:
        case LogicalKeyboardKey.keyD:
          provider.move(Direction.right);
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowUp:
        case LogicalKeyboardKey.keyW:
          provider.move(Direction.up);
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowDown:
        case LogicalKeyboardKey.keyS:
          provider.move(Direction.down);
          return KeyEventResult.handled;
        default:
          return KeyEventResult.ignored;
      }
    };
  }
}

class _Board extends StatelessWidget {
  final double boardSize;

  const _Board({required this.boardSize});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameProvider>().state;
    final size = state.difficulty.gridSize;
    final gap = boardGap(size);
    final cellSize = (boardSize - gap * (size + 1)) / size;
    final radius = (boardSize * 0.028).clamp(8.0, 14.0);

    double left(int col) => gap + col * (cellSize + gap);
    double top(int row) => gap + row * (cellSize + gap);

    // Absorbed tiles render behind active tiles so they slide under the merge result
    final absorbed = state.tiles.where((t) => t.isAbsorbed).toList();
    final active = state.tiles.where((t) => !t.isAbsorbed).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.boardBackground,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Empty cell grid
          for (int r = 0; r < size; r++)
            for (int c = 0; c < size; c++)
              Positioned(
                left: left(c),
                top: top(r),
                width: cellSize,
                height: cellSize,
                child: _EmptyCell(cellSize: cellSize),
              ),

          // Absorbed tiles (behind)
          for (final tile in absorbed)
            AnimatedPositioned(
              key: ValueKey(tile.id),
              duration: kMoveAnimationDuration,
              curve: Curves.easeInOut,
              left: left(tile.col),
              top: top(tile.row),
              width: cellSize,
              height: cellSize,
              child: TileWidget(tile: tile, cellSize: cellSize),
            ),

          // Active tiles (on top)
          for (final tile in active)
            AnimatedPositioned(
              key: ValueKey(tile.id),
              duration: kMoveAnimationDuration,
              curve: Curves.easeInOut,
              left: left(tile.col),
              top: top(tile.row),
              width: cellSize,
              height: cellSize,
              child: TileWidget(tile: tile, cellSize: cellSize),
            ),
        ],
      ),
    );
  }
}

class _EmptyCell extends StatelessWidget {
  final double cellSize;

  const _EmptyCell({required this.cellSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.emptyCell,
        borderRadius: BorderRadius.circular(tileRadius(cellSize)),
      ),
    );
  }
}
