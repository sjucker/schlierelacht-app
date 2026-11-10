import '../models/message.dart';
import 'api_client.dart';
import 'api_paths.dart';

/// Meldungen: `GET /api/v1/message` — the active ones, most important first.
class MessageApi {
  MessageApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<Message>> fetchActive() async {
    final list = await _client.getList(ApiPaths.message);
    return list.map((e) => Message.fromJson(e as Map<String, dynamic>)).toList();
  }
}
