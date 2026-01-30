import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tema modu seçenekleri
enum ThemeModeOption {
  system,
  light,
  dark,
}

extension ThemeModeOptionExtension on ThemeModeOption {
  String get displayName {
    switch (this) {
      case ThemeModeOption.system:
        return 'Sistem';
      case ThemeModeOption.light:
        return 'Açık';
      case ThemeModeOption.dark:
        return 'Koyu';
    }
  }

  IconData get icon {
    switch (this) {
      case ThemeModeOption.system:
        return Icons.brightness_auto;
      case ThemeModeOption.light:
        return Icons.light_mode;
      case ThemeModeOption.dark:
        return Icons.dark_mode;
    }
  }

  ThemeMode get themeMode {
    switch (this) {
      case ThemeModeOption.system:
        return ThemeMode.system;
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
    }
  }
}

const _themeModeKey = 'theme_mode';

/// SharedPreferences provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

/// Tema modu notifier
class ThemeModeNotifier extends StateNotifier<ThemeModeOption> {
  final SharedPreferences _prefs;

  ThemeModeNotifier(this._prefs) : super(_loadThemeMode(_prefs));

  static ThemeModeOption _loadThemeMode(SharedPreferences prefs) {
    final index = prefs.getInt(_themeModeKey);
    if (index == null || index < 0 || index >= ThemeModeOption.values.length) {
      return ThemeModeOption.system;
    }
    return ThemeModeOption.values[index];
  }

  Future<void> setThemeMode(ThemeModeOption mode) async {
    await _prefs.setInt(_themeModeKey, mode.index);
    state = mode;
  }
}

/// Tema modu provider
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeModeOption>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

/// ThemeMode provider (Flutter'ın ThemeMode'unu döndürür)
final appThemeModeProvider = Provider<ThemeMode>((ref) {
  final themeModeOption = ref.watch(themeModeProvider);
  return themeModeOption.themeMode;
});
