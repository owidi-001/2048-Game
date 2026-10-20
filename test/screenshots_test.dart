import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ndoto_2048/models/game_state.dart';

import 'helpers/app_harness.dart';

/// Renders the real app into PNGs under docs/screenshots for visual review.
/// Opt in with `GAME_SCREENSHOTS=1 flutter test test/screenshots_test.dart`.
void main() {
  final enabled = Platform.environment['GAME_SCREENSHOTS'] == '1';
  const out = 'docs/screenshots';

  Future<void> shot(WidgetTester tester, String name) =>
      screenshot(tester, '$out/$name.png');

  testWidgets('fresh game 4x4 (phone)', (tester) async {
    await pumpApp(tester, size: Devices.phone);
    await shot(tester, '01_fresh_4x4_phone');
  }, skip: !enabled);

  for (final d in Difficulty.values) {
    testWidgets('mid game ${d.gridLabel} (phone)', (tester) async {
      final p = await pumpApp(tester, size: Devices.phone);
      p.debugSetState(midGameBoard(d, bestAtStart: 9000));
      await shot(tester, '02_midgame_${d.gridSize}x${d.gridSize}_phone');
    }, skip: !enabled);
  }

  testWidgets('game over with new record (phone)', (tester) async {
    final p = await pumpApp(tester, size: Devices.phone);
    p.debugSetState(
      gameOverBoard(Difficulty.easy, score: 12480, bestAtStart: 9000),
    );
    await shot(tester, '03_gameover_record_phone');
  }, skip: !enabled);

  testWidgets('game over without record (phone)', (tester) async {
    final p = await pumpApp(
      tester,
      size: Devices.phone,
      prefs: {'best_score_5': 30000},
    );
    p.debugSetState(
      gameOverBoard(Difficulty.medium, score: 4120, bestAtStart: 30000),
    );
    await shot(tester, '04_gameover_norecord_phone');
  }, skip: !enabled);

  testWidgets('win overlay (phone)', (tester) async {
    final p = await pumpApp(
      tester,
      size: Devices.phone,
      prefs: {'best_score_4': 15000},
    );
    p.debugSetState(winBoard(bestAtStart: 15000));
    await shot(tester, '05_win_phone');
  }, skip: !enabled);

  testWidgets('how to play sheet (phone)', (tester) async {
    await pumpApp(tester, size: Devices.phone);
    await tester.tap(find.text('How to play'));
    await tester.pumpAndSettle();
    await shot(tester, '06_howtoplay_phone');
  }, skip: !enabled);

  testWidgets('confirm dialog (phone)', (tester) async {
    final p = await pumpApp(tester, size: Devices.phone);
    p.debugSetState(midGameBoard(Difficulty.easy));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hard'));
    await tester.pumpAndSettle();
    await shot(tester, '07_confirm_switch_phone');
  }, skip: !enabled);

  testWidgets('difficulty sheet (phone)', (tester) async {
    final p = await pumpApp(tester, size: Devices.phone);
    p.debugSetState(
      gameOverBoard(Difficulty.hard, score: 100, bestAtStart: 500),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change difficulty'));
    await tester.pumpAndSettle();
    await shot(tester, '08_difficulty_sheet_phone');
  }, skip: !enabled);

  testWidgets('compact 360x640 8x8', (tester) async {
    final p = await pumpApp(tester, size: Devices.compact);
    p.debugSetState(midGameBoard(Difficulty.expert));
    await shot(tester, '09_compact_8x8');
  }, skip: !enabled);

  testWidgets('iPhone SE 4x4', (tester) async {
    final p = await pumpApp(tester, size: Devices.iphoneSE);
    p.debugSetState(midGameBoard(Difficulty.easy));
    await shot(tester, '10_se_4x4');
  }, skip: !enabled);

  testWidgets('tablet landscape 6x6', (tester) async {
    final p = await pumpApp(
      tester,
      size: Devices.tabletLandscape,
      pixelRatio: 1.5,
    );
    p.debugSetState(midGameBoard(Difficulty.hard));
    await shot(tester, '11_tablet_landscape_6x6');
  }, skip: !enabled);

  testWidgets('phone landscape 4x4', (tester) async {
    final p = await pumpApp(tester, size: Devices.phoneLandscape);
    p.debugSetState(midGameBoard(Difficulty.easy));
    await shot(tester, '12_phone_landscape_4x4');
  }, skip: !enabled);

  testWidgets('tablet portrait 5x5', (tester) async {
    final p = await pumpApp(
      tester,
      size: Devices.tabletPortrait,
      pixelRatio: 1.5,
    );
    p.debugSetState(midGameBoard(Difficulty.medium));
    await shot(tester, '13_tablet_portrait_5x5');
  }, skip: !enabled);

  testWidgets('large text scale 1.3 (phone)', (tester) async {
    final p = await pumpApp(tester, size: Devices.phone);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    p.debugSetState(midGameBoard(Difficulty.easy));
    await tester.pumpAndSettle();
    await shot(tester, '14_textscale_phone');
  }, skip: !enabled);

  testWidgets('seven-digit score, compact width, 1.3x text', (tester) async {
    final p = await pumpApp(
      tester,
      size: Devices.compact,
      prefs: {'best_score_4': 1048576},
    );
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    p.debugSetState(
      midGameBoard(
        Difficulty.easy,
        bestAtStart: 1048576,
      ).copyWith(score: 1234567),
    );
    await tester.pumpAndSettle();
    await shot(tester, '15_bigscore_compact_textscale');
  }, skip: !enabled);

  testWidgets('game over, seven-digit score, compact', (tester) async {
    final p = await pumpApp(
      tester,
      size: Devices.compact,
      prefs: {'best_score_4': 1048576},
    );
    p.debugSetState(
      gameOverBoard(Difficulty.easy, score: 1234567, bestAtStart: 1048576),
    );
    await shot(tester, '16_gameover_bigscore_compact');
  }, skip: !enabled);
}
