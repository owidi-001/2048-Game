import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the bundled Rubik family and the Material icon font so widget tests
/// (and the screenshot suite) render real glyphs instead of the Ahem boxes.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  final rubik = FontLoader('Rubik');
  for (final w in [500, 600, 700, 800, 900]) {
    rubik.addFont(rootBundle.load('assets/fonts/Rubik-$w.ttf'));
  }
  await rubik.load();

  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    final icons = File(
      '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (icons.existsSync()) {
      final loader = FontLoader('MaterialIcons')
        ..addFont(
          icons.readAsBytes().then(
            (b) => ByteData.view(Uint8List.fromList(b).buffer),
          ),
        );
      await loader.load();
    }
  }

  await testMain();
}
