import '../models/gallery.dart';
import 'api_client.dart';
import 'api_paths.dart';

/// Gallery endpoint: `GET /api/v1/gallery` — image categories with their
/// Cloudflare image ids.
class GalleryApi {
  GalleryApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<GalleryCategory>> fetchGallery() async {
    final list = await _client.getList(ApiPaths.gallery);
    return list
        .map((e) => GalleryCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
