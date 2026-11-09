import 'api_client.dart';
import 'api_paths.dart';

/// Registers this device's FCM token with the backend so it can receive
/// targeted pushes. Mirrors backend `POST /api/v1/push/register`
/// (`PushRegistrationDTO` = token + platform + optional locale).
class PushApi {
  PushApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<void> register({required String token, required String platform, String? locale}) =>
      _client.postJson(ApiPaths.pushRegister, {'token': token, 'platform': platform, 'locale': ?locale});
}
