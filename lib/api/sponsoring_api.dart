import '../models/sponsoring.dart';
import 'api_client.dart';
import 'api_paths.dart';

/// Sponsoring endpoints: `GET /api/v1/sponsoring` — all sponsors with their
/// type — and `GET /api/v1/sponsoring/type` — the tiers with display titles.
class SponsoringApi {
  SponsoringApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<Sponsoring>> fetchSponsorings() async {
    final list = await _client.getList(ApiPaths.sponsoring);
    return list
        .map((e) => Sponsoring.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SponsoringTypeInfo>> fetchTypes() async {
    final list = await _client.getList('${ApiPaths.sponsoring}/type');
    return list
        .map((e) => SponsoringTypeInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
