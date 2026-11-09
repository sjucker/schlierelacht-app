import '../models/programm_point.dart';
import 'api_client.dart';
import 'api_paths.dart';

/// Event endpoint: `GET /api/v1/event` — the Wirtschaft/Gewerbe events
/// (`AttractionType.EVENT`) as programm points, shaped and sorted exactly like
/// `/api/v1/programm` but kept out of the general programm.
class EventApi {
  EventApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<ProgrammPoint>> fetchEvents() async {
    final list = await _client.getList(ApiPaths.event);
    return list.map((e) => ProgrammPoint.fromJson(e as Map<String, dynamic>)).toList();
  }
}
