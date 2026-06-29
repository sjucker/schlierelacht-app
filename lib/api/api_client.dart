import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

/// Thrown when an API request fails (non-2xx response or transport error).
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}

/// Minimal REST helper against the public backend API (`/api/**`).
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

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

  Future<dynamic> _getJson(String path) async {
    final http.Response response;
    try {
      response = await _client.get(_uri(path));
    } catch (e) {
      throw ApiException('Verbindung fehlgeschlagen: $e');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('Fehler ${response.statusCode} bei $path');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }
}
