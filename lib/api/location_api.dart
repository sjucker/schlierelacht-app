import '../models/location.dart';
import 'api_client.dart';
import 'api_paths.dart';

/// Location endpoints: `GET /api/v1/location` — all festival locations (stages,
/// stands, bars, …) with coordinates — and `GET /api/v1/location/{externalId}`.
class LocationApi {
  LocationApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<Location>> fetchLocations() async {
    final list = await _client.getList(ApiPaths.location);
    return list.map((e) => Location.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Location> fetchLocation(String externalId) async {
    final json = await _client.getObject('${ApiPaths.location}/$externalId');
    return Location.fromJson(json);
  }
}
