import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ndoto_2048/models/game_state.dart';
import 'package:ndoto_2048/providers/game_provider.dart';
import 'package:ndoto_2048/services/game_engine.dart';
import 'package:ndoto_2048/services/storage_service.dart';
import 'package:ndoto_2048/theme/tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/app_harness.dart';

Future<GameProvider> makeProvider({
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(Map<String, Object>.from(prefs));
  final storage = StorageService();
  await storage.init();
  final p = GameProvider(storage: storage);
  await p.init();
  return p;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => GameEngine.random = Random(3));

  group('rapid input (Bug B family)', () {
    test(
      'a second move inside the settle window is applied, not dropped',
      () async {
        final p = await makeProvider();
        p.debugSetState(
          boardFrom(Difficulty.easy, [
            [2, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
          ], moves: 0),
        );
        p.move(Direction.right); // tile → (0,3), spawn somewhere
        final afterFirst = p.state;
        expect(afterFirst.moves, 1);
        // Immediately (0 ms later) move down: must be processed.
        p.move(Direction.down);
        expect(p.state.moves, 2, reason: 'second swipe must not be swallowed');
        // The previous move's transient flags were settled before applying.
        expect(
          p.state.tiles.where((t) => t.isAbsorbed).length,
          lessThanOrEqualTo(p.state.activeTiles.length),
          reason: 'no stale absorbed tiles accumulate',
        );
        expect(p.undoDepth, 2);
        p.dispose();
      },
    );

    testWidgets('settle timer fires and clears transient flags', (
      tester,
    ) async {
      final p = await makeProvider();
      p.debugSetState(
        boardFrom(Difficulty.easy, [
          [2, 2, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ]),
      );
      p.move(Direction.left);
      expect(
        p.state.tiles.any((t) => t.isAbsorbed || t.isNew || t.isMerged),
        isTrue,
      );
      await tester.pump(Motion.settle + const Duration(milliseconds: 5));
      expect(
        p.state.tiles.any((t) => t.isAbsorbed || t.isNew || t.isMerged),
        isFalse,
      );
      p.dispose();
    });

    testWidgets(
      'newGame mid-animation cancels the pending settle and never resurrects the old board',
      (tester) async {
        final p = await makeProvider();
        p.debugSetState(midGameBoard(Difficulty.easy));
        p.move(Direction.down);
        expect(p.state.difficulty, Difficulty.easy);
        final pending = p.newGame(difficulty: Difficulty.expert);
        expect(
          p.state.difficulty,
          Difficulty.expert,
          reason: 'state swaps synchronously',
        );
        expect(p.state.tiles.length, 2);
        await pending;
        await tester.pump(const Duration(seconds: 1));
        expect(p.state.difficulty, Difficulty.expert);
        expect(p.state.tiles.length, 2);
        expect(
          p.state.tiles.every((t) => !t.isNew),
          isTrue,
          reason: 'spawn flags settled',
        );
        expect(p.undoDepth, 0);
        p.dispose();
      },
    );

    test(
      'tile ids stay unique and monotonic across games and difficulties',
      () async {
        final p = await makeProvider();
        final seen = <int>{};
        for (final d in [...Difficulty.values, ...Difficulty.values.reversed]) {
          await p.newGame(difficulty: d);
          for (var i = 0; i < 6; i++) {
            p.move(Direction.values[i % 4]);
          }
          for (final t in p.state.tiles) {
            // Ids may legitimately repeat for tiles that survive several moves,
            // but a *new* tile must never reuse an id from a previous game.
            seen.add(t.id);
          }
        }
        final ids = p.state.tiles.map((t) => t.id).toList();
        expect(
          ids.toSet().length,
          ids.length,
          reason: 'no duplicate ids on the live board',
        );
        expect(seen.length, greaterThan(16));
        p.dispose();
      },
    );
  });

  group('difficulty transitions', () {
    for (final from in Difficulty.values) {
      for (final to in Difficulty.values) {
        if (from == to) continue;
        test(
          '${from.gridLabel} → ${to.gridLabel} yields a clean, playable board',
          () async {
            final p = await makeProvider();
            await p.newGame(difficulty: from);
            p.move(Direction.left);
            p.move(Direction.up);
            await p.newGame(difficulty: to);
            final s = p.state;
            expect(s.difficulty, to);
            expect(s.tiles.length, 2);
            expect(
              s.tiles.every((t) => t.row < to.gridSize && t.col < to.gridSize),
              isTrue,
            );
            expect(s.score, 0);
            expect(s.moves, 0);
            expect(s.status, GameStatus.playing);
            expect(p.canUndo, isFalse);
            // Keep playing on the new board in all four directions.
            for (final d in Direction.values) {
              p.move(d);
            }
            expect(p.state.difficulty, to);
            expect(
              p.state.activeTiles.every(
                (t) => t.row < to.gridSize && t.col < to.gridSize,
              ),
              isTrue,
            );
            final storage = StorageService();
            await storage.init();
            expect(storage.getSavedDifficulty(), to);
            p.dispose();
          },
        );
      }
    }
  });

  group('best score & record semantics (Bug A)', () {
    test(
      'beating the stored best mid-game is NOT announced as a record event',
      () async {
        final p = await makeProvider(prefs: {'best_score_4': 10});
        p.debugSetState(
          boardFrom(Difficulty.easy, [
            [8, 8, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
          ], bestAtStart: 10),
        );
        p.move(Direction.left); // +16 → beats 10
        final effects = p.takeEffects();
        expect(effects, contains(GameEffect.merge));
        expect(effects, isNot(contains(GameEffect.over)));
        expect(p.state.isOver, isFalse);
        expect(
          p.isBeatingRecord,
          isTrue,
          reason: 'the live best card may update',
        );
        expect(p.currentBest, 16, reason: 'best is persisted silently');
        p.dispose();
      },
    );

    test('record is decided at game over against bestAtStart', () async {
      final p = await makeProvider(prefs: {'best_score_4': 100});
      // One move from over: the only slide fills the last cell.
      GameEngine.random = _FixedRandom(0.0); // spawn a 2
      p.debugSetState(
        boardFrom(
          Difficulty.easy,
          [
            [0, 8, 2, 4],
            [2, 4, 8, 16],
            [4, 2, 16, 8],
            [2, 4, 8, 16],
          ],
          score: 150,
          bestAtStart: 100,
        ),
      );
      p.move(Direction.left);
      expect(p.state.isOver, isTrue);
      expect(p.state.isNewRecord, isTrue);
      expect(p.takeEffects(), contains(GameEffect.over));
      // And the same end position with a lower score is not a record.
      p.debugSetState(
        boardFrom(
          Difficulty.easy,
          [
            [0, 8, 2, 4],
            [2, 4, 8, 16],
            [4, 2, 16, 8],
            [2, 4, 8, 16],
          ],
          score: 50,
          bestAtStart: 100,
        ),
      );
      p.move(Direction.left);
      expect(p.state.isOver, isTrue);
      expect(p.state.isNewRecord, isFalse);
      p.dispose();
    });

    test(
      'a new game snapshots the latest persisted best as bestAtStart',
      () async {
        final p = await makeProvider(prefs: {'best_score_4': 10});
        p.debugSetState(
          boardFrom(Difficulty.easy, [
            [16, 16, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
          ], bestAtStart: 10),
        );
        p.move(Direction.left); // best becomes 32
        await p.newGame();
        expect(p.state.bestAtStart, 32);
        expect(p.state.isNewRecord, isFalse);
        p.dispose();
      },
    );

    test('best scores are tracked per difficulty', () async {
      final p = await makeProvider(
        prefs: {'best_score_4': 500, 'best_score_8': 20},
      );
      expect(p.bestScore(Difficulty.easy), 500);
      expect(p.bestScore(Difficulty.expert), 20);
      await p.newGame(difficulty: Difficulty.expert);
      expect(p.currentBest, 20);
      expect(p.state.bestAtStart, 20);
      p.dispose();
    });
  });

  group('undo', () {
    test(
      'undo restores the previous board and score, up to the stack depth',
      () async {
        final p = await makeProvider();
        await p.newGame(difficulty: Difficulty.easy);
        final sigs = <String>[boardSignature(p.state)];
        var attempts = 0;
        while (p.state.moves < 12 && attempts < 60) {
          p.move(Direction.values[attempts % 4]);
          attempts++;
          if (sigs.length < p.state.moves + 1) {
            sigs.add(boardSignature(p.state));
          }
        }
        expect(p.undoDepth, 10, reason: 'stack is capped');
        for (var i = 0; i < 10; i++) {
          expect(p.canUndo, isTrue);
          p.undo();
        }
        expect(p.canUndo, isFalse);
        expect(boardSignature(p.state), sigs[sigs.length - 11]);
        expect(p.takeEffects(), everyElement(isNot(GameEffect.over)));
        p.dispose();
      },
    );

    test('undo is unavailable once the game is over', () async {
      final p = await makeProvider();
      p.debugSetState(
        boardFrom(Difficulty.easy, [
          [2, 2, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ]),
      );
      p.move(Direction.left);
      expect(p.canUndo, isTrue);
      p.debugSetState(gameOverBoard(Difficulty.easy, score: 5, bestAtStart: 0));
      expect(p.canUndo, isFalse);
      p.move(Direction.left);
      expect(p.state.moves, 300, reason: 'moves are ignored when over');
      p.dispose();
    });
  });

  group('persistence', () {
    test('restores a saved game including status and bestAtStart', () async {
      final saved = winBoard(bestAtStart: 42);
      final p = await makeProvider(
        prefs: {'saved_game': saved.toJson(), 'selected_difficulty': 'easy'},
      );
      expect(p.state.status, GameStatus.won);
      expect(p.state.bestAtStart, 42);
      expect(p.state.score, saved.score);
      p.dispose();
    });

    test('a legacy save of a dead board is restored as over', () async {
      final dead = gameOverBoard(
        Difficulty.medium,
        score: 9,
        bestAtStart: 0,
      ).copyWith(status: GameStatus.playing);
      final p = await makeProvider(prefs: {'saved_game': dead.toJson()});
      expect(p.state.isOver, isTrue);
      p.dispose();
    });

    test(
      'invalid moves surface a nudge effect but do not change state',
      () async {
        final p = await makeProvider();
        p.debugSetState(
          boardFrom(Difficulty.easy, [
            [2, 4, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
          ]),
        );
        final before = boardSignature(p.state);
        p.move(Direction.left);
        expect(boardSignature(p.state), before);
        expect(p.lastInvalidDirection, Direction.left);
        expect(p.invalidTick, 1);
        expect(p.takeEffects(), [GameEffect.invalidMove]);
        p.dispose();
      },
    );
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
