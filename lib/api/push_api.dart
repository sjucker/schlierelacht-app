import 'api_client.dart';

/// Registers this device's FCM token with the backend so it can receive
/// targeted pushes. Mirrors backend `POST /api/push/register`
/// (`PushRegistrationDTO` = token + platform + optional locale).
class PushApi {
  PushApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<void> register({
    required String token,
    required String platform,
    String? locale,
  }) =>
      _client.postJson('/api/push/register', {
        'token': token,
        'platform': platform,
        'locale': ?locale,
      });
}
