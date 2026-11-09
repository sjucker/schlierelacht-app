import '../models/meetup.dart';
import 'api_client.dart';
import 'api_paths.dart';

/// Jahrgangstreffen endpoints: `GET /api/v1/meetup` (public participant list)
/// and `POST /api/v1/meetup` (registration).
class MeetupApi {
  MeetupApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<MeetupEntry>> fetchEntries() async {
    final list = await _client.getList(ApiPaths.meetup);
    return list
        .map((e) => MeetupEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> register(MeetupRegistration registration) =>
      _client.postJson(ApiPaths.meetup, registration.toJson());
}
