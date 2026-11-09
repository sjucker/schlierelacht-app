import '../models/news.dart';
import 'api_client.dart';
import 'api_paths.dart';

/// News endpoints: `GET /api/v1/news` and `GET /api/v1/news/{id}`.
class NewsApi {
  NewsApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<News>> fetchNews() async {
    final list = await _client.getList(ApiPaths.news);
    return list
        .map((e) => News.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<News> fetchNewsById(int id) async {
    final json = await _client.getObject('${ApiPaths.news}/$id');
    return News.fromJson(json);
  }
}
