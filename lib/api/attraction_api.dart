import '../models/attraction.dart';
import '../models/attraction_type.dart';
import 'api_client.dart';

/// Attraction endpoints: list (`GET /api/attraction`, optionally filtered by
/// `?type=`) and detail (`GET /api/attraction/{externalId}`).
class AttractionApi {
  AttractionApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// Fetches attractions, optionally restricted to the given [types]
  /// (e.g. `{AttractionType.food}` for the gastro list).
  Future<List<Attraction>> fetchAttractions({Set<AttractionType>? types}) async {
    var path = '/api/attraction';
    if (types != null && types.isNotEmpty) {
      path += '?type=${types.map((t) => t.wire).join(',')}';
    }
    final list = await _client.getList(path);
    return list
        .map((e) => Attraction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Attraction> fetchAttraction(String externalId) async {
    final json = await _client.getObject('/api/attraction/$externalId');
    return Attraction.fromJson(json);
  }
}
