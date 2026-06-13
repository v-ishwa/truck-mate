import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/theme_preferences.dart';

class ThemeLocalDatasource {
  static final ThemeLocalDatasource _instance = ThemeLocalDatasource._internal();
  factory ThemeLocalDatasource() => _instance;
  ThemeLocalDatasource._internal();

  late final Isar _isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    // Use Isar.getInstance() or open if not already open to prevent multiple open errors
    final existingInstance = Isar.getInstance();
    if (existingInstance != null) {
      _isar = existingInstance;
    } else {
      _isar = await Isar.open(
        [ThemePreferencesSchema],
        directory: dir.path,
      );
    }
  }

  /// Retrieves the theme mode preference. If it's the first run,
  /// queries the host system brightness and persists that value in Isar.
  Future<String> getThemeMode() async {
    final prefs = await _isar.themePreferences.filter().keyEqualTo('theme_preference').findFirst();
    if (prefs == null) {
      // First run: default is 'system'
      final newPrefs = ThemePreferences()
        ..key = 'theme_preference'
        ..themeMode = 'system';
      
      await _isar.writeTxn(() async {
        await _isar.themePreferences.put(newPrefs);
      });
      
      return 'system';
    }
    return prefs.themeMode;
  }

  /// Saves the user's manual theme selection ('light' or 'dark') to Isar database.
  Future<void> saveThemeMode(String mode) async {
    final existing = await _isar.themePreferences.filter().keyEqualTo('theme_preference').findFirst();
    final prefs = existing ?? (ThemePreferences()..key = 'theme_preference');
    prefs.themeMode = mode;
    
    await _isar.writeTxn(() async {
      await _isar.themePreferences.put(prefs);
    });
  }
}
