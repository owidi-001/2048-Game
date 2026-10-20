import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndoto_2048/main.dart';
import 'package:ndoto_2048/models/game_state.dart';
import 'package:ndoto_2048/models/tile.dart';
import 'package:ndoto_2048/providers/game_provider.dart';
import 'package:ndoto_2048/services/game_engine.dart';
import 'package:ndoto_2048/services/storage_service.dart';
import 'package:ndoto_2048/widgets/game_board_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Common phone / tablet viewports (logical px).
class Devices {
  static const compact = Size(360, 640); // small Android
  static const iphoneSE = Size(375, 667);
  static const phone = Size(390, 844); // iPhone 14/15
  static const phoneLarge = Size(430, 932);
  static const tabletPortrait = Size(820, 1180);
  static const tabletLandscape = Size(1180, 820);
  static const phoneLandscape = Size(844, 390);
}

final _rootKey = GlobalKey();

/// Pumps the real app at [size] with an in-memory store and returns the provider.
Future<GameProvider> pumpApp(
  WidgetTester tester, {
  Size size = Devices.phone,
  double pixelRatio = 2,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(Map<String, Object>.from(prefs));
  tester.view.physicalSize = size * pixelRatio;
  tester.view.devicePixelRatio = pixelRatio;
  addTearDown(tester.view.reset);

  final storage = StorageService();
  await storage.init();
  final provider = GameProvider(storage: storage);
  await provider.init();

  await tester.pumpWidget(
    RepaintBoundary(
      key: _rootKey,
      child: ChangeNotifierProvider<GameProvider>.value(
        value: provider,
        child: const Ndoto2048App(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return provider;
}

/// Swipes the board in [direction] and waits for the move to settle.
Future<void> swipe(WidgetTester tester, Direction direction) async {
  final offset = switch (direction) {
    Direction.left => const Offset(-160, 0),
    Direction.right => const Offset(160, 0),
    Direction.up => const Offset(0, -160),
    Direction.down => const Offset(0, 160),
  };
  await tester.fling(find.byType(GameBoardWidget), offset, 1200);
  await tester.pumpAndSettle(const Duration(milliseconds: 400));
}

/// Stable signature of a board (ignores animation flags).
String boardSignature(GameState s) =>
    (s.activeTiles.map((t) => '${t.id}:${t.value}@${t.row},${t.col}').toList()
          ..sort())
        .join('|');

/// Writes a PNG of the whole app to [path] (directories created as needed).
Future<void> screenshot(
  WidgetTester tester,
  String path, {
  double pixelRatio = 2,
}) async {
  await tester.pumpAndSettle();
  final boundary =
      _rootKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(path)..createSync(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

// -----------------------------------------------------------------------------
// Deterministic fixtures
// -----------------------------------------------------------------------------

/// Builds a state from a grid of values (0 = empty).
GameState boardFrom(
  Difficulty difficulty,
  List<List<int>> grid, {
  int score = 0,
  int bestAtStart = 0,
  int moves = 1,
  GameStatus? status,
  bool hasWonAlready = false,
}) {
  final tiles = <Tile>[];
  var id = 1;
  for (var r = 0; r < grid.length; r++) {
    for (var c = 0; c < grid[r].length; c++) {
      if (grid[r][c] > 0) {
        tiles.add(Tile(id: id++, value: grid[r][c], row: r, col: c));
      }
    }
  }
  final state = GameState(
    tiles: tiles,
    score: score,
    status: status ?? GameStatus.playing,
    difficulty: difficulty,
    bestAtStart: bestAtStart,
    moves: moves,
    hasWonAlready: hasWonAlready,
  );
  if (status == null && !GameEngine.canMove(state)) {
    return state.copyWith(status: GameStatus.over);
  }
  return state;
}

/// A believable mid-game board for any size, with a spread of values.
GameState midGameBoard(Difficulty d, {int bestAtStart = 0}) {
  final n = d.gridSize;
  final values = [2048, 1024, 512, 256, 128, 64, 32, 16, 8, 4, 2];
  final grid = List.generate(n, (_) => List.filled(n, 0));
  // Snake the high values along the top rows, scatter small ones below.
  var k = 0;
  for (var c = 0; c < n && k < values.length; c++) {
    grid[0][c] = values[k++];
  }
  for (var c = n - 1; c >= 0 && k < values.length; c--) {
    grid[1][c] = values[k++];
  }
  final smalls = [2, 4, 2, 8, 4, 2, 16, 2, 4, 2, 2, 8, 4, 2, 32, 2, 4];
  var s = 0;
  for (var r = 2; r < n; r++) {
    for (var c = 0; c < n; c++) {
      if ((r + c) % 3 == 0 && s < smalls.length) grid[r][c] = smalls[s++];
    }
  }
  final score = values.fold(0, (a, b) => a + b) * 3;
  return boardFrom(d, grid, score: score, bestAtStart: bestAtStart, moves: 140);
}

/// A full board with no merges available → game over.
GameState gameOverBoard(
  Difficulty d, {
  required int score,
  required int bestAtStart,
}) {
  final n = d.gridSize;
  final grid = List.generate(n, (_) => List.filled(n, 0));
  // Guarantee no two equal neighbours by alternating distinct value families.
  for (var r = 0; r < n; r++) {
    for (var c = 0; c < n; c++) {
      grid[r][c] = (r + c).isEven
          ? [2, 8, 32][(r * n + c) % 3]
          : [4, 16, 64][(r * n + c) % 3];
    }
  }
  return boardFrom(d, grid, score: score, bestAtStart: bestAtStart, moves: 300);
}

/// A board with a freshly made 2048 tile (win pending).
GameState winBoard({int bestAtStart = 0}) {
  final grid = [
    [2048, 1024, 8, 2],
    [4, 16, 32, 0],
    [2, 0, 0, 0],
    [0, 0, 0, 4],
  ];
  return boardFrom(
    Difficulty.easy,
    grid,
    score: 20832,
    bestAtStart: bestAtStart,
    moves: 900,
    status: GameStatus.won,
    hasWonAlready: true,
  );
}
