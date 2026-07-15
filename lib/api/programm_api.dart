import '../models/programm_point.dart';
import 'api_client.dart';

/// Programm endpoint: `GET /api/programm` — every programm entry joined with its
/// attraction, pre-sorted chronologically by the backend.
class ProgrammApi {
  ProgrammApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<ProgrammPoint>> fetchProgramm() async {
    final list = await _client.getList('/api/programm');
    return list
        .map((e) => ProgrammPoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
