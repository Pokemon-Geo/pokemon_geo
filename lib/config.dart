import 'package:shared_preferences/shared_preferences.dart';

class Config {
  static late final SharedPreferences _prefs;

  static const String darkModeKey = "darkMode";
  static bool darkMode = true;

  static const String uuidKey = "uuid";
  static String uuid = "A37CA11D-5D72-97CD-3312-8E6D288C572S";

  static Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    darkMode = _prefs.getBool(darkModeKey) ?? true;
    uuid = _prefs.getString(uuidKey) ?? "A37CA11D-5D72-97CD-3312-8E6D288C572S";
  }

  static Future<void> save() async {
    _prefs.setBool(darkModeKey, darkMode);
    _prefs.setString(uuidKey, uuid);
  }
}
