import '../models/location.dart';
import 'api_client.dart';

/// Location endpoint: `GET /api/location` — all festival locations (stages,
/// stands, bars, …) with coordinates for the map and list.
class LocationApi {
  LocationApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<Location>> fetchLocations() async {
    final list = await _client.getList('/api/location');
    return list
        .map((e) => Location.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
