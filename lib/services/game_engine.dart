import 'dart:math';
import '../models/tile.dart';
import '../models/game_state.dart';

enum Direction { left, right, up, down }

class MoveResult {
  final GameState state;
  final bool moved;
  final int scoreGain;

  const MoveResult({
    required this.state,
    required this.moved,
    this.scoreGain = 0,
  });
}

class GameEngine {
  GameEngine._();

  static GameState newGame(Difficulty difficulty, int Function() nextId) {
    final size = difficulty.gridSize;
    final tiles = <Tile>[];
    final allPositions = [
      for (int r = 0; r < size; r++)
        for (int c = 0; c < size; c++) (row: r, col: c),
    ]..shuffle(Random());

    tiles.add(Tile(
      id: nextId(),
      value: _randomValue(),
      row: allPositions[0].row,
      col: allPositions[0].col,
      isNew: true,
    ));
    tiles.add(Tile(
      id: nextId(),
      value: _randomValue(),
      row: allPositions[1].row,
      col: allPositions[1].col,
      isNew: true,
    ));

    return GameState(
      tiles: tiles,
      score: 0,
      status: GameStatus.playing,
      difficulty: difficulty,
    );
  }

  static MoveResult move({
    required GameState state,
    required Direction direction,
    required int Function() nextId,
  }) {
    final size = state.difficulty.gridSize;
    // Ignore absorbed tiles from previous frame that weren't cleaned up yet
    final current = state.tiles.where((t) => !t.isAbsorbed).toList();

    final allActive = <Tile>[];
    final allAbsorbed = <Tile>[];
    int totalScore = 0;
    bool anyMoved = false;

    if (direction == Direction.left || direction == Direction.right) {
      final leftward = direction == Direction.left;
      for (int r = 0; r < size; r++) {
        final rowTiles = current.where((t) => t.row == r).toList();
        final result = _processLine(
          tiles: rowTiles,
          size: size,
          forward: leftward,
          useCol: true,
          fixedIndex: r,
        );
        allActive.addAll(result.active);
        allAbsorbed.addAll(result.absorbed);
        totalScore += result.score;
        if (result.moved) anyMoved = true;
      }
    } else {
      final upward = direction == Direction.up;
      for (int c = 0; c < size; c++) {
        final colTiles = current.where((t) => t.col == c).toList();
        final result = _processLine(
          tiles: colTiles,
          size: size,
          forward: upward,
          useCol: false,
          fixedIndex: c,
        );
        allActive.addAll(result.active);
        allAbsorbed.addAll(result.absorbed);
        totalScore += result.score;
        if (result.moved) anyMoved = true;
      }
    }

    if (!anyMoved) return MoveResult(state: state, moved: false);

    // Spawn a new tile in a random empty cell
    final occupied = allActive.map((t) => (t.row, t.col)).toSet();
    final empty = <(int, int)>[];
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (!occupied.contains((r, c))) empty.add((r, c));
      }
    }
    if (empty.isNotEmpty) {
      final pos = empty[Random().nextInt(empty.length)];
      allActive.add(Tile(
        id: nextId(),
        value: _randomValue(),
        row: pos.$1,
        col: pos.$2,
        isNew: true,
      ));
    }

    final newScore = state.score + totalScore;
    final justWon = !state.hasWonAlready && allActive.any((t) => t.value >= 2048);
    final isOver = !_canMove(allActive, size);

    final GameStatus newStatus;
    if (justWon) {
      newStatus = GameStatus.won;
    } else if (isOver) {
      newStatus = GameStatus.over;
    } else if (state.hasWonAlready || state.status == GameStatus.continueAfterWin) {
      newStatus = GameStatus.continueAfterWin;
    } else {
      newStatus = GameStatus.playing;
    }

    return MoveResult(
      state: GameState(
        tiles: [...allActive, ...allAbsorbed],
        score: newScore,
        status: newStatus,
        difficulty: state.difficulty,
        hasWonAlready: state.hasWonAlready || justWon,
      ),
      moved: true,
      scoreGain: totalScore,
    );
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  static _LineResult _processLine({
    required List<Tile> tiles,
    required int size,
    required bool forward, // true = compact toward 0, false = toward size-1
    required bool useCol, // true = we're processing a row (varying col)
    required int fixedIndex, // the row (for useCol=true) or col (for useCol=false)
  }) {
    if (tiles.isEmpty) return const _LineResult(active: [], absorbed: [], score: 0, moved: false);

    // Sort in movement direction
    final sorted = List<Tile>.from(tiles);
    sorted.sort((a, b) {
      final posA = useCol ? a.col : a.row;
      final posB = useCol ? b.col : b.row;
      return forward ? posA.compareTo(posB) : posB.compareTo(posA);
    });

    final active = <Tile>[];
    final absorbed = <Tile>[];
    int score = 0;
    bool moved = false;
    int outIdx = 0;

    int i = 0;
    while (i < sorted.length) {
      final dest = forward ? outIdx : (size - 1 - outIdx);
      final curPos = useCol ? sorted[i].col : sorted[i].row;

      if (i + 1 < sorted.length && sorted[i].value == sorted[i + 1].value) {
        // Merge pair
        final mergedValue = sorted[i].value * 2;
        score += mergedValue;
        moved = true;

        active.add(Tile(
          id: sorted[i].id,
          value: mergedValue,
          row: useCol ? fixedIndex : dest,
          col: useCol ? dest : fixedIndex,
          isMerged: true,
        ));

        absorbed.add(Tile(
          id: sorted[i + 1].id,
          value: sorted[i + 1].value,
          row: useCol ? fixedIndex : dest,
          col: useCol ? dest : fixedIndex,
          isAbsorbed: true,
        ));

        outIdx++;
        i += 2;
      } else {
        // Move or stay
        if (dest != curPos) moved = true;

        active.add(Tile(
          id: sorted[i].id,
          value: sorted[i].value,
          row: useCol ? fixedIndex : dest,
          col: useCol ? dest : fixedIndex,
        ));

        outIdx++;
        i++;
      }
    }

    return _LineResult(active: active, absorbed: absorbed, score: score, moved: moved);
  }

  static bool _canMove(List<Tile> tiles, int size) {
    if (tiles.length < size * size) return true;

    final grid = List.generate(size, (_) => List<int>.filled(size, 0));
    for (final t in tiles) {
      grid[t.row][t.col] = t.value;
    }

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (c + 1 < size && grid[r][c] == grid[r][c + 1]) return true;
        if (r + 1 < size && grid[r][c] == grid[r + 1][c]) return true;
      }
    }
    return false;
  }

  static int _randomValue() => Random().nextDouble() < 0.9 ? 2 : 4;
}

class _LineResult {
  final List<Tile> active;
  final List<Tile> absorbed;
  final int score;
  final bool moved;

  const _LineResult({
    required this.active,
    required this.absorbed,
    required this.score,
    required this.moved,
  });
}
