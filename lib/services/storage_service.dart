import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state.dart';

class StorageService {
  static const _difficultyKey = 'selected_difficulty';
  static const _savedGameKey = 'saved_game';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Best scores (per difficulty)

  int getBestScore(Difficulty difficulty) {
    return _prefs.getInt(difficulty.storageKey) ?? 0;
  }

  Future<void> saveBestScore(Difficulty difficulty, int score) async {
    await _prefs.setInt(difficulty.storageKey, score);
  }

  // Selected difficulty

  Difficulty? getSavedDifficulty() {
    final name = _prefs.getString(_difficultyKey);
    if (name == null) return null;
    return DifficultyX.fromString(name);
  }

  Future<void> saveDifficulty(Difficulty difficulty) async {
    await _prefs.setString(_difficultyKey, difficulty.name);
  }

  // Last game state

  GameState? getSavedGame() {
    final json = _prefs.getString(_savedGameKey);
    if (json == null) return null;
    try {
      return GameState.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveGame(GameState state) async {
    await _prefs.setString(_savedGameKey, state.toJson());
  }

  Future<void> clearSavedGame() async {
    await _prefs.remove(_savedGameKey);
  }
}
