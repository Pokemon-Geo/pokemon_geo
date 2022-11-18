import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

class ConfigValue<T> {
  String key;
  T value;
  String Function(T)? encoder;
  T Function(String)? decoder;

  ConfigValue(this.key, this.value, [this.encoder, this.decoder]);

  void load() {
    // default value set by ctor
    if (!Config._prefs.containsKey(key)) return;
    if (decoder != null) {
      value = decoder!.call(Config._prefs.getString(key)!);
    } else {
      switch (T) {
        case String:
          value = Config._prefs.getString(key)! as T;
          break;
        case int:
          value = Config._prefs.getInt(key)! as T;
          break;
        case double:
          value = Config._prefs.getDouble(key)! as T;
          break;
        case bool:
          value = Config._prefs.getBool(key)! as T;
          break;
        case List<String>:
          value = Config._prefs.getStringList(key)! as T;
          break;
        default:
          log("Please define decoder for type $T");
          break;
      }
    }
  }

  void set(T newValue) {
    value = newValue;
    if (encoder != null) {
      Config._prefs.setString(key, encoder!.call(newValue));
    } else {
      switch (T) {
        case String:
          Config._prefs.setString(key, value as String);
          break;
        case int:
          Config._prefs.setInt(key, value as int);
          break;
        case double:
          Config._prefs.setDouble(key, value as double);
          break;
        case bool:
          Config._prefs.setBool(key, value as bool);
          break;
        case List<String>:
          Config._prefs.setStringList(key, value as List<String>);
          break;
        default:
          log("Please define encoder for type $T");
          break;
      }
    }
  }
}

class Config {
  static late final SharedPreferences _prefs;

  static final ConfigValue<bool> _darkMode = register("darkMode", true);

  static get darkMode => _darkMode.value;

  static set darkMode(s) => _darkMode.set(s);

  static final ConfigValue<String> _uuid =
      register("email", "a661f146-06d2-4729-bfde-4d97e1620ea3");

  static get uuid => _uuid.value;

  static set uuid(s) => _uuid.set(s);

  static final List<ConfigValue> _values = [];

  static ConfigValue<T> register<T>(String key, T value) {
    var cfg = ConfigValue(key, value);
    _values.add(cfg);
    return cfg;
  }

  static Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    for (var value in _values) {
      value.load();
    }
  }
}
