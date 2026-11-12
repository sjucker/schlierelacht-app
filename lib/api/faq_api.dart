import '../models/faq.dart';
import 'api_client.dart';
import 'api_paths.dart';

/// FAQ: `GET /api/v1/faq` — the active entries, grouped, in display order.
class FaqApi {
  FaqApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<FaqGroup>> fetchFaq() async {
    final list = await _client.getList(ApiPaths.faq);
    return list.map((e) => FaqGroup.fromJson(e as Map<String, dynamic>)).toList();
  }
}
