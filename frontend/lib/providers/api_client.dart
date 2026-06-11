import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'auth_provider.dart';
import 'settings_provider.dart';

class ApiClient {
  final Ref _ref;

  ApiClient(this._ref);

  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> request(
    String path, {
    required String method,
    Map<String, dynamic>? body,
  }) async {
    final settings = _ref.read(settingsProvider);
    final authState = _ref.read(authProvider);
    final url = Uri.parse('${settings.apiUrl}$path');

    Future<http.Response> execute(String? token) {
      final headers = _headers(token);
      final bodyStr = body != null ? jsonEncode(body) : null;
      switch (method.toUpperCase()) {
        case 'POST':
          return http.post(url, headers: headers, body: bodyStr);
        case 'PUT':
          return http.put(url, headers: headers, body: bodyStr);
        case 'DELETE':
          return http.delete(url, headers: headers);
        default:
          return http.get(url, headers: headers);
      }
    }

    var response = await execute(authState.accessToken);

    if (response.statusCode == 401 && authState.refreshToken != null) {
      // Access token might be expired. Try to refresh.
      final refreshed = await _ref.read(authProvider.notifier).refreshAccessToken();
      if (refreshed) {
        // Retry with new token
        final newAuthState = _ref.read(authProvider);
        response = await execute(newAuthState.accessToken);
      }
    }

    return response;
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref);
});
