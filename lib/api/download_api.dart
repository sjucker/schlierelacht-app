import '../config.dart';
import '../models/download.dart';
import 'api_client.dart';
import 'api_paths.dart';

/// Downloads endpoints: `GET /api/v1/downloads` (list) and
/// `GET /api/v1/downloads/{id}/file` (the file itself).
class DownloadApi {
  DownloadApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<Download>> fetchDownloads() async {
    final list = await _client.getList(ApiPaths.downloads);
    return list
        .map((e) => Download.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Absolute URL of a download, opened in the browser to fetch the file.
  static String fileUrl(int id) => '$apiBaseUrl${ApiPaths.downloads}/$id/file';
}
