import '../models/meetup.dart';
import 'api_client.dart';
import 'api_paths.dart';

/// Jahrgangstreffen endpoint: `GET /api/v1/meetup` (public participant list).
/// Registration (`POST`) is only possible on the website, not in the app.
class MeetupApi {
  MeetupApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<MeetupEntry>> fetchEntries() async {
    final list = await _client.getList(ApiPaths.meetup);
    return list.map((e) => MeetupEntry.fromJson(e as Map<String, dynamic>)).toList();
  }
}
