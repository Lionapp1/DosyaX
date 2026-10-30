import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  static const _kTheme = 'theme_mode';
  static const _kPin = 'private_pin';
  static const _kGrid = 'prefer_grid';

  ThemeMode themeMode = ThemeMode.system;
  bool preferGrid = true;
  String? _pin;

  bool get hasPrivatePin => _pin != null && _pin!.isNotEmpty;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final t = p.getString(_kTheme) ?? 'system';
    themeMode = switch (t) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    preferGrid = p.getBool(_kGrid) ?? true;
    _pin = p.getString(_kPin);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    final p = await SharedPreferences.getInstance();
    final v = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await p.setString(_kTheme, v);
    notifyListeners();
  }

  Future<void> setPreferGrid(bool v) async {
    preferGrid = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kGrid, v);
    notifyListeners();
  }

  Future<void> setPrivatePin(String pin) async {
    _pin = pin;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kPin, pin);
    notifyListeners();
  }

  Future<void> clearPrivatePin() async {
    _pin = null;
    final p = await SharedPreferences.getInstance();
    await p.remove(_kPin);
    notifyListeners();
  }

  bool checkPin(String input) => _pin != null && input == _pin;
}
