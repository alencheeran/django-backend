import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final String apiUrl;
  final String wsUrl;

  SettingsState({required this.apiUrl, required this.wsUrl});

  SettingsState copyWith({String? apiUrl, String? wsUrl}) {
    return SettingsState(
      apiUrl: apiUrl ?? this.apiUrl,
      wsUrl: wsUrl ?? this.wsUrl,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SharedPreferences _prefs;

  SettingsNotifier(this._prefs)
      : super(SettingsState(
          apiUrl: _prefs.getString('api_url') ?? 'http://192.168.29.48:8000',
          wsUrl: _prefs.getString('ws_url') ?? 'ws://192.168.29.48:8000',
        ));

  Future<void> updateSettings({required String apiUrl, required String wsUrl}) async {
    // Normalize trailing slashes
    var cleanApi = apiUrl.trim();
    if (cleanApi.endsWith('/')) {
      cleanApi = cleanApi.substring(0, cleanApi.length - 1);
    }
    var cleanWs = wsUrl.trim();
    if (cleanWs.endsWith('/')) {
      cleanWs = cleanWs.substring(0, cleanWs.length - 1);
    }

    await _prefs.setString('api_url', cleanApi);
    await _prefs.setString('ws_url', cleanWs);
    state = SettingsState(apiUrl: cleanApi, wsUrl: cleanWs);
  }

  Future<void> resetSettings() async {
    await _prefs.remove('api_url');
    await _prefs.remove('ws_url');
    state = SettingsState(
      apiUrl: 'http://127.0.0.1:8000',
      wsUrl: 'ws://127.0.0.1:8000',
    );
  }
}

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize in main() by overriding this provider');
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final prefs = ref.read(sharedPrefsProvider);
  return SettingsNotifier(prefs);
});
