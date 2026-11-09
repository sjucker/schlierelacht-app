import '../config.dart';
import '../models/attraction.dart';
import '../models/attraction_type.dart';
import 'api_client.dart';
import 'api_paths.dart';

/// Attraction endpoints: list (`GET /api/v1/attraction`, optionally filtered by
/// `?type=`), detail (`GET /api/v1/attraction/{externalId}`) and file download
/// (`GET /api/v1/attraction/{externalId}/files/{id}`).
class AttractionApi {
  AttractionApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// Fetches attractions, optionally restricted to the given [types]
  /// (e.g. `{AttractionType.food}` for the gastro list).
  Future<List<Attraction>> fetchAttractions({Set<AttractionType>? types}) async {
    var path = ApiPaths.attraction;
    if (types != null && types.isNotEmpty) {
      path += '?type=${types.map((t) => t.wire).join(',')}';
    }
    final list = await _client.getList(path);
    return list.map((e) => Attraction.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Attraction> fetchAttraction(String externalId) async {
    final json = await _client.getObject('${ApiPaths.attraction}/$externalId');
    return Attraction.fromJson(json);
  }

  /// Absolute URL of an attraction file, opened in the browser to download.
  static String fileUrl(String externalId, int fileId) => '$apiBaseUrl${ApiPaths.attraction}/$externalId/files/$fileId';
}
