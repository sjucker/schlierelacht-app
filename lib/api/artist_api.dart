import '../models/attraction.dart';
import 'api_client.dart';

/// Artist endpoints: `GET /api/artist` and `GET /api/artist/{externalId}`.
/// The Programm schedule is derived from the attractions returned here.
class ArtistApi {
  ArtistApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<Attraction>> fetchArtists() async {
    final list = await _client.getList('/api/artist');
    return list
        .map((e) => Attraction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Attraction> fetchArtist(String externalId) async {
    final json = await _client.getObject('/api/artist/$externalId');
    return Attraction.fromJson(json);
  }
}
