import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/game_provider.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'theme/game_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = StorageService();
  await storage.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => GameProvider(storage: storage)..init(),
      child: const Ndoto2048App(),
    ),
  );
}

/// Root widget. Exposed so tests can pump the real app.
class Ndoto2048App extends StatelessWidget {
  const Ndoto2048App({super.key});

  @override
  Widget build(BuildContext context) {
    const game = GameTheme.midnight;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: game.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: MaterialApp(
        title: '2048',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(game),
        home: const HomeScreen(),
      ),
    );
  }
}
