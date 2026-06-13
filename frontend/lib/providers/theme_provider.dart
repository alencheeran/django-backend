import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_provider.dart';

enum AppThemeMode {
  hybrid, // Light sheets (mockup style)
  dark,   // Pure dark/slate sheets
}

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  final SharedPreferences _prefs;

  ThemeNotifier(this._prefs)
      : super(_loadTheme(_prefs));

  static AppThemeMode _loadTheme(SharedPreferences prefs) {
    final val = prefs.getString('app_theme_mode');
    if (val == 'dark') {
      return AppThemeMode.dark;
    }
    return AppThemeMode.hybrid;
  }

  Future<void> toggleTheme() async {
    if (state == AppThemeMode.hybrid) {
      state = AppThemeMode.dark;
      await _prefs.setString('app_theme_mode', 'dark');
    } else {
      state = AppThemeMode.hybrid;
      await _prefs.setString('app_theme_mode', 'hybrid');
    }
  }

  bool get isDark => state == AppThemeMode.dark;
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  final prefs = ref.read(sharedPrefsProvider);
  return ThemeNotifier(prefs);
});
