import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ndoto_2048/models/game_state.dart';
import 'package:ndoto_2048/services/game_engine.dart';

import 'helpers/app_harness.dart';

List<List<int>> gridOf(GameState s) {
  final n = s.difficulty.gridSize;
  final g = List.generate(n, (_) => List.filled(n, 0));
  for (final t in s.activeTiles) {
    g[t.row][t.col] = t.value;
  }
  return g;
}

/// Applies a move and strips the spawned tile so the slide/merge result can be
/// compared exactly.
List<List<int>> slideOnly(GameState s, Direction d) {
  var id = 100;
  final r = GameEngine.move(state: s, direction: d, nextId: () => ++id);
  final g = gridOf(r.state);
  for (final t in r.state.activeTiles.where((t) => t.isNew)) {
    g[t.row][t.col] = 0;
  }
  return g;
}

void main() {
  setUp(() => GameEngine.random = Random(7));

  group('GameEngine.newGame', () {
    for (final d in Difficulty.values) {
      test('${d.gridLabel} starts with two tiles inside the board', () {
        var id = 0;
        final s = GameEngine.newGame(d, () => ++id, bestAtStart: 123);
        expect(s.tiles.length, 2);
        expect(
          s.tiles.every((t) => t.row < d.gridSize && t.col < d.gridSize),
          isTrue,
        );
        expect(s.tiles.every((t) => t.value == 2 || t.value == 4), isTrue);
        expect(s.score, 0);
        expect(s.moves, 0);
        expect(s.bestAtStart, 123);
        expect(s.status, GameStatus.playing);
        expect(s.hasProgress, isFalse);
      });
    }
  });

  group('GameEngine.move', () {
    test('slides tiles left and merges once per pair', () {
      final s = boardFrom(Difficulty.easy, [
        [2, 2, 2, 2],
        [4, 0, 4, 0],
        [2, 4, 2, 4],
        [0, 0, 0, 8],
      ]);
      expect(slideOnly(s, Direction.left), [
        [4, 4, 0, 0],
        [8, 0, 0, 0],
        [2, 4, 2, 4],
        [8, 0, 0, 0],
      ]);
    });

    test('merges toward the move direction first (right)', () {
      final s = boardFrom(Difficulty.easy, [
        [2, 2, 2, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      expect(slideOnly(s, Direction.right)[0], [0, 0, 2, 4]);
      expect(slideOnly(s, Direction.left)[0], [4, 2, 0, 0]);
    });

    test('up and down work on non-square-sized boards too (5x5)', () {
      final s = boardFrom(Difficulty.medium, [
        [2, 0, 0, 0, 0],
        [2, 0, 0, 0, 0],
        [4, 0, 0, 0, 0],
        [0, 0, 0, 0, 0],
        [4, 0, 0, 0, 0],
      ]);
      final up = slideOnly(s, Direction.up);
      expect([for (var r = 0; r < 5; r++) up[r][0]], [4, 8, 0, 0, 0]);
      final down = slideOnly(s, Direction.down);
      expect([for (var r = 0; r < 5; r++) down[r][0]], [0, 0, 0, 4, 8]);
    });

    test('adds merged values to the score and increments moves', () {
      final s = boardFrom(
        Difficulty.easy,
        [
          [2, 2, 0, 0],
          [4, 4, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ],
        score: 10,
        moves: 3,
      );
      var id = 10;
      final r = GameEngine.move(
        state: s,
        direction: Direction.left,
        nextId: () => ++id,
      );
      expect(r.moved, isTrue);
      expect(r.scoreGain, 12);
      expect(r.state.score, 22);
      expect(r.state.moves, 4);
      expect(
        r.state.activeTiles.where((t) => t.isNew).length,
        1,
        reason: 'one tile spawns per move',
      );
    });

    test(
      'a move that changes nothing is reported as not moved and spawns nothing',
      () {
        final s = boardFrom(Difficulty.easy, [
          [2, 4, 0, 0],
          [8, 16, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ], moves: 5);
        var id = 10;
        final r = GameEngine.move(
          state: s,
          direction: Direction.left,
          nextId: () => ++id,
        );
        expect(r.moved, isFalse);
        expect(r.scoreGain, 0);
        expect(r.state.moves, 5);
        expect(r.state.activeTiles.length, 4);
        expect(id, 10, reason: 'no id consumed');
      },
    );

    test('keeps merged source tiles as absorbed for the animation', () {
      final s = boardFrom(Difficulty.easy, [
        [2, 2, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      var id = 10;
      final r = GameEngine.move(
        state: s,
        direction: Direction.left,
        nextId: () => ++id,
      );
      final absorbed = r.state.tiles.where((t) => t.isAbsorbed).toList();
      expect(absorbed.length, 1);
      expect(
        absorbed.single.col,
        0,
        reason: 'absorbed tile animates to the merge target',
      );
      expect(r.state.activeTiles.where((t) => t.isMerged).single.value, 4);
    });

    test('reaching 2048 sets status won exactly once', () {
      final s = boardFrom(Difficulty.easy, [
        [1024, 1024, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      var id = 10;
      final r = GameEngine.move(
        state: s,
        direction: Direction.left,
        nextId: () => ++id,
      );
      expect(r.state.status, GameStatus.won);
      expect(r.state.hasWonAlready, isTrue);

      // After continuing, further merges above 2048 do not re-trigger the win.
      final cont = r.state.copyWith(status: GameStatus.continueAfterWin);
      final again = boardFrom(
        Difficulty.easy,
        [
          [2048, 2048, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ],
        hasWonAlready: true,
        status: GameStatus.continueAfterWin,
      );
      expect(cont.status, GameStatus.continueAfterWin);
      final r2 = GameEngine.move(
        state: again,
        direction: Direction.left,
        nextId: () => ++id,
      );
      expect(r2.state.status, GameStatus.continueAfterWin);
      expect(r2.state.highestTile, 4096);
    });

    test('a board with no slides or merges left becomes over', () {
      // One empty cell; sliding row 0 left opens (0,3) and the spawned 2 has
      // no equal neighbour, so the result is a genuinely dead board.
      final s = boardFrom(Difficulty.easy, [
        [0, 8, 2, 4],
        [2, 4, 8, 16],
        [4, 2, 16, 8],
        [2, 4, 8, 16],
      ]);
      expect(GameEngine.canMove(s), isTrue);
      GameEngine.random = _FixedRandom(0.0); // spawn value 2
      var id = 10;
      final r = GameEngine.move(
        state: s,
        direction: Direction.left,
        nextId: () => ++id,
      );
      expect(r.moved, isTrue);
      expect(r.state.activeTiles.length, 16);
      expect(r.state.status, GameStatus.over);
      expect(GameEngine.canMove(r.state), isFalse);
    });

    test(
      'a move that only rearranges a full board without merges stays playing',
      () {
        final s = boardFrom(Difficulty.easy, [
          [0, 2, 4, 2],
          [4, 8, 2, 4],
          [2, 4, 8, 2],
          [4, 2, 4, 8],
        ]);
        GameEngine.random = _FixedRandom(0.95); // spawn value 4
        var id = 10;
        final r = GameEngine.move(
          state: s,
          direction: Direction.left,
          nextId: () => ++id,
        );
        // Row 0 becomes [2,4,2,4]; (0,2)=2 sits above (1,2)=2 → still a merge left.
        expect(r.moved, isTrue);
        expect(r.state.status, GameStatus.playing);
      },
    );
  });

  group('GameEngine.canMove', () {
    test(
      'is true with an empty cell, true with a mergeable pair, false otherwise',
      () {
        expect(GameEngine.canMove(midGameBoard(Difficulty.expert)), isTrue);
        expect(
          GameEngine.canMove(
            gameOverBoard(Difficulty.hard, score: 1, bestAtStart: 0),
          ),
          isFalse,
        );
        final pair = boardFrom(Difficulty.easy, [
          [2, 4, 2, 4],
          [4, 2, 4, 2],
          [2, 4, 2, 4],
          [4, 2, 4, 4],
        ]);
        expect(GameEngine.canMove(pair), isTrue);
      },
    );

    for (final d in Difficulty.values) {
      test('gameOverBoard fixture for ${d.gridLabel} is genuinely over', () {
        final s = gameOverBoard(d, score: 1, bestAtStart: 0);
        expect(s.activeTiles.length, d.gridSize * d.gridSize);
        expect(s.isOver, isTrue);
      });
    }
  });

  group('GameState', () {
    test(
      'round-trips through JSON including status, bestAtStart and moves',
      () {
        final s = winBoard(bestAtStart: 77).copyWith(moves: 12);
        final back = GameState.fromJson(s.toJson());
        expect(back.status, GameStatus.won);
        expect(back.bestAtStart, 77);
        expect(back.moves, 12);
        expect(back.score, s.score);
        expect(back.hasWonAlready, isTrue);
        expect(back.tiles.length, s.tiles.length);
      },
    );

    test('isNewRecord compares against bestAtStart, not the live best', () {
      final s = boardFrom(
        Difficulty.easy,
        [
          [2, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ],
        score: 100,
        bestAtStart: 100,
      );
      expect(s.isNewRecord, isFalse);
      expect(s.copyWith(score: 101).isNewRecord, isTrue);
      expect(
        s.copyWith(score: 0, bestAtStart: 0).isNewRecord,
        isFalse,
        reason: 'a zero score is never a record',
      );
    });
  });
}

class _FixedRandom implements Random {
  _FixedRandom(this.value);
  final double value;
  @override
  bool nextBool() => value >= 0.5;
  @override
  double nextDouble() => value;
  @override
  int nextInt(int max) => (value * max).floor().clamp(0, max - 1);
}
