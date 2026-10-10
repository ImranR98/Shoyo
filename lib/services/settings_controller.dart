import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoyo/theme/app_theme.dart';

/// Small abstraction over key-value storage so settings can be tested
/// without platform channels.
abstract class KeyValueStore {
  Future<bool?> getBool(String key);
  Future<void> setBool(String key, bool value);
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
}

class SharedPrefsStore implements KeyValueStore {
  SharedPrefsStore([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  @override
  Future<bool?> getBool(String key) => _prefs.getBool(key);

  @override
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  @override
  Future<String?> getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
}

class SettingsController extends ChangeNotifier {
  SettingsController(this._store);

  static const String promptForFilenamesKey = 'promptForFilenames';
  static const String autoRenameOnConflictKey = 'autoRenameOnConflict';
  static const String hasVisitedSettingsKey = 'hasVisitedSettings';
  static const String themeStyleKey = 'themeStyle';

  final KeyValueStore _store;

  bool _promptForFilenames = false;
  bool _autoRenameOnConflict = true;
  bool _hasVisitedSettings = false;
  AppThemeStyle _themeStyle = AppThemeStyle.classic;

  bool get promptForFilenames => _promptForFilenames;
  bool get autoRenameOnConflict => _autoRenameOnConflict;
  bool get hasVisitedSettings => _hasVisitedSettings;
  AppThemeStyle get themeStyle => _themeStyle;

  Future<void> load() async {
    _promptForFilenames = await _store.getBool(promptForFilenamesKey) ?? false;
    _autoRenameOnConflict =
        await _store.getBool(autoRenameOnConflictKey) ?? true;
    _hasVisitedSettings = await _store.getBool(hasVisitedSettingsKey) ?? false;
    _themeStyle = AppThemeStyle.fromName(await _store.getString(themeStyleKey));
    notifyListeners();
  }

  Future<void> setPromptForFilenames(bool value) async {
    if (value == _promptForFilenames) return;
    _promptForFilenames = value;
    notifyListeners();
    await _store.setBool(promptForFilenamesKey, value);
  }

  Future<void> setAutoRenameOnConflict(bool value) async {
    if (value == _autoRenameOnConflict) return;
    _autoRenameOnConflict = value;
    notifyListeners();
    await _store.setBool(autoRenameOnConflictKey, value);
  }

  Future<void> setThemeStyle(AppThemeStyle value) async {
    if (value == _themeStyle) return;
    _themeStyle = value;
    notifyListeners();
    await _store.setString(themeStyleKey, value.name);
  }

  Future<void> markSettingsVisited() async {
    if (_hasVisitedSettings) return;
    _hasVisitedSettings = true;
    notifyListeners();
    await _store.setBool(hasVisitedSettingsKey, true);
  }
}
