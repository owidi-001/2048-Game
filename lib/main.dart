import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/game_provider.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'utils/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  final storage = StorageService();
  await storage.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => GameProvider(storage: storage)..init(),
      child: const _App(),
    ),
  );
}

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2048',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFEDC22E),
          brightness: Brightness.light,
          surface: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.nunitoTextTheme(),
        splashFactory: InkRipple.splashFactory,
      ),
      home: const HomeScreen(),
    );
  }
}
