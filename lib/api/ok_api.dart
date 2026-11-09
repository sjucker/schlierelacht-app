import '../models/ok.dart';
import 'api_client.dart';
import 'api_paths.dart';

/// Organizing-committee endpoint: `GET /api/v1/ok`.
class OkApi {
  OkApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<Ok> fetchOk() async => Ok.fromJson(await _client.getObject(ApiPaths.ok));
}
