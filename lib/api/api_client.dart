import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import 'api_cache.dart';

/// Thrown when an API request fails (non-2xx response or transport error).
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}

/// Minimal REST helper against the public backend API (`/api/v<n>/**`).
/// GETs fall back to [ApiCache] when the device is offline.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// How long a GET may take before the cached copy is used instead — a weak
  /// festival-ground connection should not leave a spinner forever.
  static const requestTimeout = Duration(seconds: 10);

  final http.Client _client;

  Uri _uri(String path) => Uri.parse('$apiBaseUrl$path');

  /// GETs [path] and decodes the body as a JSON object.
  Future<Map<String, dynamic>> getObject(String path) async {
    final body = await _getJson(path);
    return body as Map<String, dynamic>;
  }

  /// GETs [path] and decodes the body as a JSON array.
  Future<List<dynamic>> getList(String path) async {
    final body = await _getJson(path);
    return body as List<dynamic>;
  }

  /// POSTs [body] as JSON to [path]. Throws [ApiException] on a non-2xx
  /// response or transport error; returns nothing (callers ignore the body).
  Future<void> postJson(String path, Map<String, dynamic> body) async {
    final http.Response response;
    try {
      response = await _client.post(_uri(path), headers: const {'Content-Type': 'application/json'}, body: jsonEncode(body));
    } catch (e) {
      throw ApiException('Verbindung fehlgeschlagen: $e');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('Fehler ${response.statusCode} bei $path');
    }
  }

  /// Network first; on a transport error, timeout or 5xx it falls back to the
  /// last cached response for [path] (see [ApiCache]). Only when nothing is
  /// cached does the error reach the screen.
  Future<dynamic> _getJson(String path) async {
    final http.Response response;
    try {
      response = await _client.get(_uri(path)).timeout(requestTimeout);
    } catch (e) {
      return _fromCache(path, ApiException('Verbindung fehlgeschlagen: $e'));
    }
    if (response.statusCode >= 500) {
      return _fromCache(path, ApiException('Fehler ${response.statusCode} bei $path'));
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('Fehler ${response.statusCode} bei $path');
    }
    final body = utf8.decode(response.bodyBytes);
    final json = jsonDecode(body);
    ApiCache.offlineSince.value = null;
    await ApiCache.put(path, body);
    return json;
  }

  Future<dynamic> _fromCache(String path, ApiException error) async {
    final cached = await ApiCache.get(path);
    if (cached == null) throw error;
    final json = jsonDecode(cached.body);
    refreshPastFlags(json, DateTime.now());
    final shown = ApiCache.offlineSince.value;
    // The banner shows the oldest data currently on screen.
    if (shown == null || cached.savedAt.isBefore(shown)) {
      ApiCache.offlineSince.value = cached.savedAt;
    }
    return json;
  }
}
