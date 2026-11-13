import 'package:material_ui/material_ui.dart';

import '../api/news_api.dart';
import '../models/news.dart';
import '../widgets/async_view.dart';
import '../widgets/news_card.dart';
import 'news_detail_screen.dart';

class NewsListScreen extends StatefulWidget {
  const NewsListScreen({super.key});

  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  final _api = NewsApi();
  late Future<List<News>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchNews();
  }

  void _reload() => setState(() {
    _future = _api.fetchNews();
  });

  /// Pull-to-refresh: the indicator spins until the new data is in, while
  /// the current list stays on screen (see [AsyncView]).
  Future<void> _refresh() {
    _reload();
    return settled(_future);
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<News>>(
      future: _future,
      onRetry: _reload,
      onData: (context, news) {
        if (news.isEmpty) {
          return const Center(child: Text('Aktuell sind keine News vorhanden.'));
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: news.length,
            itemBuilder: (context, i) => NewsCard(
              news: news[i],
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => NewsDetailScreen(newsId: news[i].id))),
            ),
          ),
        );
      },
    );
  }
}
