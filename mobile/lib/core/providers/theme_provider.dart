import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _key = 'rentlanka_theme_mode';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final value = await _storage.read(key: _key);
      if (value != null) {
        if (value == 'light') {
          state = ThemeMode.light;
        } else if (value == 'dark') {
          state = ThemeMode.dark;
        } else {
          state = ThemeMode.system;
        }
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      String value = 'system';
      if (mode == ThemeMode.light) {
        value = 'light';
      } else if (mode == ThemeMode.dark) {
        value = 'dark';
      }
      await _storage.write(key: _key, value: value);
    } catch (_) {}
  }
}

final themeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
