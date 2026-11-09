import '../models/programm_point.dart';
import 'api_client.dart';
import 'api_paths.dart';

/// Programm endpoint: `GET /api/v1/programm` — every programm entry joined
/// with its attraction, pre-sorted chronologically by the backend.
class ProgrammApi {
  ProgrammApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<ProgrammPoint>> fetchProgramm() async {
    final list = await _client.getList(ApiPaths.programm);
    return list
        .map((e) => ProgrammPoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
