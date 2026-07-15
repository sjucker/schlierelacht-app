import '../models/sponsoring.dart';
import 'api_client.dart';

/// Sponsoring endpoint: `GET /api/sponsoring` — all sponsors with their type.
class SponsoringApi {
  SponsoringApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<Sponsoring>> fetchSponsorings() async {
    final list = await _client.getList('/api/sponsoring');
    return list
        .map((e) => Sponsoring.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
