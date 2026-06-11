import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_provider.dart';

enum AuthStatus { unauthenticated, authenticating, authenticated }

class AuthState {
  final AuthStatus status;
  final String? accessToken;
  final String? refreshToken;
  final String? username;
  final String? errorMessage;

  AuthState({
    required this.status,
    this.accessToken,
    this.refreshToken,
    this.username,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? accessToken,
    String? refreshToken,
    String? username,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      accessToken: accessToken,
      refreshToken: refreshToken,
      username: username,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  final SharedPreferences _prefs;

  AuthNotifier(this._ref, this._prefs)
      : super(AuthState(status: AuthStatus.unauthenticated)) {
    _tryAutoLogin();
  }

  void _tryAutoLogin() {
    final access = _prefs.getString('access_token');
    final refresh = _prefs.getString('refresh_token');
    final username = _prefs.getString('username');

    if (access != null && refresh != null && username != null) {
      state = AuthState(
        status: AuthStatus.authenticated,
        accessToken: access,
        refreshToken: refresh,
        username: username,
      );
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
    final settings = _ref.read(settingsProvider);

    try {
      final response = await http.post(
        Uri.parse('${settings.apiUrl}/api/token/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final access = data['access'] as String;
        final refresh = data['refresh'] as String;

        await _prefs.setString('access_token', access);
        await _prefs.setString('refresh_token', refresh);
        await _prefs.setString('username', username);

        state = AuthState(
          status: AuthStatus.authenticated,
          accessToken: access,
          refreshToken: refresh,
          username: username,
        );
        return true;
      } else {
        final data = jsonDecode(response.body);
        final message = data['detail'] ?? data['error'] ?? 'Login failed. Please check credentials.';
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: message.toString(),
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Connection to server failed. Verify API URL in Settings.',
      );
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
    final settings = _ref.read(settingsProvider);

    try {
      final response = await http.post(
        Uri.parse('${settings.apiUrl}/api/users/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        // Automatically login on success
        return await login(username, password);
      } else {
        final data = jsonDecode(response.body);
        // Concatenate dictionary errors if returned
        String errMsg = 'Registration failed.';
        if (data is Map) {
          final buffer = StringBuffer();
          data.forEach((key, value) {
            buffer.write('$key: $value\n');
          });
          errMsg = buffer.toString().trim();
        }
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: errMsg,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Connection error. Registration failed.',
      );
      return false;
    }
  }

  Future<bool> refreshAccessToken() async {
    if (state.refreshToken == null) return false;
    final settings = _ref.read(settingsProvider);

    try {
      final response = await http.post(
        Uri.parse('${settings.apiUrl}/api/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': state.refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccess = data['access'] as String;

        await _prefs.setString('access_token', newAccess);

        state = state.copyWith(
          status: AuthStatus.authenticated,
          accessToken: newAccess,
          refreshToken: state.refreshToken,
          username: state.username,
        );
        return true;
      } else {
        // Refresh token invalid or expired, force logout
        logout();
        return false;
      }
    } catch (e) {
      return false; // Connection issue, don't force logout immediately
    }
  }

  Future<void> logout() async {
    await _prefs.remove('access_token');
    await _prefs.remove('refresh_token');
    await _prefs.remove('username');

    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final prefs = ref.read(sharedPrefsProvider);
  return AuthNotifier(ref, prefs);
});
