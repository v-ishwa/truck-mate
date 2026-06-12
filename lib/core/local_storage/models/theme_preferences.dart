import 'package:isar/isar.dart';

part 'theme_preferences.g.dart';

@collection
class ThemePreferences {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String key = 'theme_preference';

  // Can be 'system', 'light', or 'dark'
  String themeMode = 'system';
}
