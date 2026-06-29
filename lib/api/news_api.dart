import '../models/news.dart';
import 'api_client.dart';

/// News endpoints: `GET /api/news` and `GET /api/news/{id}`.
class NewsApi {
  NewsApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<News>> fetchNews() async {
    final list = await _client.getList('/api/news');
    return list
        .map((e) => News.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<News> fetchNewsById(int id) async {
    final json = await _client.getObject('/api/news/$id');
    return News.fromJson(json);
  }
}
