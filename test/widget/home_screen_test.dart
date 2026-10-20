import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndoto_2048/models/game_state.dart';
import 'package:ndoto_2048/providers/game_provider.dart';
import 'package:ndoto_2048/services/game_engine.dart';
import 'package:ndoto_2048/widgets/game_board_widget.dart';
import 'package:ndoto_2048/widgets/tile_widget.dart';

import '../helpers/app_harness.dart';

/// Tapping a difficulty chip in the segmented selector (portrait layout).
Future<void> tapDifficulty(WidgetTester tester, Difficulty d) async {
  await tester.tap(find.text(d.label).first);
  await tester.pump();
}

Future<void> confirmSwitch(WidgetTester tester) async {
  await tester.pumpAndSettle();
  expect(find.text('Switch'), findsOneWidget, reason: 'confirmation expected');
  await tester.tap(find.text('Switch'));
  await tester.pumpAndSettle();
}

/// The end-of-game panel (the overlay host itself is always mounted).
Finder overlayPanel() => find.byWidgetPredicate(
  (w) => w.key == const ValueKey('over') || w.key == const ValueKey('won'),
);

/// Asserts the rendered board matches the provider state for [d].
void expectBoardConsistent(WidgetTester tester, GameProvider p, Difficulty d) {
  final s = p.state;
  expect(s.difficulty, d);
  expect(overlayPanel(), findsNothing);
  final rendered = tester
      .widgetList<TileWidget>(find.byType(TileWidget))
      .toList();
  // Every live tile is drawn exactly once, and nothing from a previous board lingers.
  final liveIds = s.activeTiles.map((t) => t.id).toSet();
  final drawnIds = rendered.map((w) => w.tile.id).toList();
  expect(drawnIds.toSet(), liveIds, reason: 'rendered tiles == live tiles');
  expect(
    drawnIds.length,
    drawnIds.toSet().length,
    reason: 'no duplicate tile widgets',
  );
  for (final t in s.activeTiles) {
    expect(t.row, lessThan(d.gridSize));
    expect(t.col, lessThan(d.gridSize));
  }
  // The board itself is square and the selector highlights the new difficulty.
  final boardSize = tester.getSize(find.byType(GameBoardWidget));
  expect((boardSize.width - boardSize.height).abs(), lessThan(1));
}

void main() {
  setUp(() => GameEngine.random = Random(11));

  group('difficulty transition matrix (12 directed transitions)', () {
    for (final from in Difficulty.values) {
      for (final to in Difficulty.values) {
        if (from == to) continue;

        testWidgets(
          '${from.gridLabel} → ${to.gridLabel} via chip + confirm, then play',
          (tester) async {
            final p = await pumpApp(tester);
            p.debugSetState(midGameBoard(from));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);

            await tapDifficulty(tester, to);
            await confirmSwitch(tester);
            expectBoardConsistent(tester, p, to);
            expect(p.state.moves, 0);
            expect(p.state.score, 0);

            // Play all four directions on the new board through real gestures.
            for (final dir in Direction.values) {
              await swipe(tester, dir);
            }
            expect(p.state.difficulty, to);
            expect(
              p.state.moves,
              greaterThan(0),
              reason: 'swipes are recognised after the switch',
            );
            expectBoardConsistent(tester, p, to);
            expect(tester.takeException(), isNull);
          },
        );

        testWidgets(
          '${from.gridLabel} → ${to.gridLabel} mid-animation (fresh board, no dialog)',
          (tester) async {
            final p = await pumpApp(tester);
            await p.newGame(difficulty: from);
            await tester.pumpAndSettle();
            // Kick off a move and switch while its animation is still running.
            var attempts = 0;
            while (p.state.moves == 0 && attempts < 4) {
              p.move(Direction.values[attempts++]);
            }
            await tester.pump(const Duration(milliseconds: 40));
            // The board now has progress, so the chip asks for confirmation.
            await tapDifficulty(tester, to);
            await confirmSwitch(tester);
            await tester.pumpAndSettle();
            expectBoardConsistent(tester, p, to);
            for (final dir in Direction.values) {
              await swipe(tester, dir);
            }
            expect(p.state.difficulty, to);
            expectBoardConsistent(tester, p, to);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }

    testWidgets('a round trip through every size keeps the board clean', (
      tester,
    ) async {
      final p = await pumpApp(tester);
      final order = [
        ...Difficulty.values,
        ...Difficulty.values.reversed,
        Difficulty.expert,
        Difficulty.easy,
      ];
      for (final d in order) {
        if (d == p.state.difficulty) continue;
        await tapDifficulty(tester, d);
        if (p.state.hasProgress) await confirmSwitch(tester);
        await tester.pumpAndSettle();
        await swipe(tester, Direction.left);
        await swipe(tester, Direction.down);
        expectBoardConsistent(tester, p, d);
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('confirmations', () {
    testWidgets('switching from a fresh board does not ask', (tester) async {
      final p = await pumpApp(tester);
      expect(p.state.hasProgress, isFalse);
      await tapDifficulty(tester, Difficulty.hard);
      await tester.pumpAndSettle();
      expect(find.text('Switch'), findsNothing);
      expect(p.state.difficulty, Difficulty.hard);
    });

    testWidgets('cancelling the switch keeps the current game intact', (
      tester,
    ) async {
      final p = await pumpApp(tester);
      p.debugSetState(midGameBoard(Difficulty.easy));
      await tester.pumpAndSettle();
      final before = boardSignature(p.state);
      await tapDifficulty(tester, Difficulty.expert);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(p.state.difficulty, Difficulty.easy);
      expect(boardSignature(p.state), before);
    });

    testWidgets('New game asks only when there is progress', (tester) async {
      final p = await pumpApp(tester);
      await tester.tap(find.text('New game'));
      await tester.pumpAndSettle();
      expect(find.text('Start a new game?'), findsNothing);

      p.debugSetState(midGameBoard(Difficulty.easy));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New game'));
      await tester.pumpAndSettle();
      expect(find.text('Start a new game?'), findsOneWidget);
      await tester.tap(find.text('New game').last);
      await tester.pumpAndSettle();
      expect(p.state.moves, 0);
      expect(p.state.tiles.length, 2);
    });
  });

  group('record announcement (Bug A)', () {
    testWidgets(
      'no overlay or record banner while playing, even when beating the best',
      (tester) async {
        final p = await pumpApp(tester, prefs: {'best_score_4': 10});
        p.debugSetState(
          boardFrom(Difficulty.easy, [
            [8, 8, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
          ], bestAtStart: 10),
        );
        await tester.pumpAndSettle();
        await swipe(tester, Direction.left);
        expect(p.state.score, 16);
        expect(overlayPanel(), findsNothing);
        expect(find.textContaining('record', findRichText: true), findsNothing);
        expect(
          find.text('16'),
          findsWidgets,
          reason: 'the live best card updates silently',
        );
      },
    );

    testWidgets('game over with a record shows the record overlay once', (
      tester,
    ) async {
      final p = await pumpApp(tester, prefs: {'best_score_4': 100});
      GameEngine.random = _FixedRandom(0.0);
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
      await tester.pumpAndSettle();
      await swipe(tester, Direction.left);
      expect(p.state.isOver, isTrue);
      expect(overlayPanel(), findsOneWidget);
      expect(find.text('New record!'), findsOneWidget);
      expect(find.text('Play again'), findsOneWidget);
      // Re-rendering does not duplicate the announcement.
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('New record!'), findsOneWidget);
    });

    testWidgets('game over without a record says Game over', (tester) async {
      final p = await pumpApp(tester, prefs: {'best_score_4': 1000});
      p.debugSetState(
        gameOverBoard(Difficulty.easy, score: 150, bestAtStart: 1000),
      );
      await tester.pumpAndSettle();
      expect(find.text('Game over'), findsOneWidget);
      expect(find.text('New record!'), findsNothing);
      await tester.tap(find.text('Play again'));
      await tester.pumpAndSettle();
      expect(p.state.isOver, isFalse);
      expect(overlayPanel(), findsNothing);
    });

    testWidgets('win overlay offers Keep going and resumes play', (
      tester,
    ) async {
      final p = await pumpApp(tester);
      p.debugSetState(winBoard());
      await tester.pumpAndSettle();
      expect(find.text('You made 2048!'), findsOneWidget);
      expect(
        find.text('New record!'),
        findsNothing,
        reason: 'records are announced at game over',
      );
      await tester.tap(find.text('Keep going'));
      await tester.pumpAndSettle();
      expect(overlayPanel(), findsNothing);
      expect(p.state.status, GameStatus.continueAfterWin);
      await swipe(tester, Direction.down);
      expect(p.state.moves, greaterThan(900));
    });
  });

  group('layout robustness', () {
    for (final entry in {
      'compact 360x640': Devices.compact,
      'iPhone SE': Devices.iphoneSE,
      'phone': Devices.phone,
      'phone landscape': Devices.phoneLandscape,
      'tablet portrait': Devices.tabletPortrait,
      'tablet landscape': Devices.tabletLandscape,
    }.entries) {
      testWidgets('${entry.key}: every difficulty renders without overflow', (
        tester,
      ) async {
        final p = await pumpApp(tester, size: entry.value);
        for (final d in Difficulty.values) {
          p.debugSetState(midGameBoard(d));
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${entry.key} ${d.gridLabel}',
          );
          final cells = tester.widgetList<TileWidget>(find.byType(TileWidget));
          expect(cells.length, p.state.activeTiles.length);
        }
        p.debugSetState(
          gameOverBoard(Difficulty.expert, score: 1, bestAtStart: 0),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '${entry.key} overlay');
      });
    }

    testWidgets('1.3x text scale renders without overflow', (tester) async {
      final p = await pumpApp(tester, size: Devices.compact);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final d in Difficulty.values) {
        p.debugSetState(midGameBoard(d, bestAtStart: 999999));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: d.gridLabel);
      }
      await tester.tap(find.text('How to play'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('how to play sheet opens and closes', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('How to play'));
      await tester.pumpAndSettle();
      expect(find.text('Swipe to slide'), findsOneWidget);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.text('Swipe to slide'), findsNothing);
    });

    testWidgets('8x8 tiles keep a readable font size on a 360px-wide phone', (
      tester,
    ) async {
      final p = await pumpApp(tester, size: Devices.compact);
      p.debugSetState(midGameBoard(Difficulty.expert));
      await tester.pumpAndSettle();
      final texts = tester.widgetList<Text>(
        find.descendant(
          of: find.byType(TileWidget),
          matching: find.byType(Text),
        ),
      );
      for (final t in texts) {
        expect(
          t.style!.fontSize,
          greaterThanOrEqualTo(11),
          reason: 'tile ${t.data}',
        );
      }
    });
  });

  group('input', () {
    testWidgets('keyboard arrows move the board', (tester) async {
      final p = await pumpApp(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(p.state.moves, greaterThan(0));
    });

    testWidgets('two quick swipes both register', (tester) async {
      final p = await pumpApp(tester);
      p.debugSetState(
        boardFrom(Difficulty.easy, [
          [2, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ], moves: 0),
      );
      await tester.pumpAndSettle();
      await tester.fling(
        find.byType(GameBoardWidget),
        const Offset(160, 0),
        1200,
      );
      await tester.pump(const Duration(milliseconds: 30));
      await tester.fling(
        find.byType(GameBoardWidget),
        const Offset(0, 160),
        1200,
      );
      await tester.pumpAndSettle();
      expect(p.state.moves, 2);
      expect(tester.takeException(), isNull);
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
