import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../api/news_api.dart';
import '../models/news.dart';
import '../utils/external_links.dart';
import '../utils/formatting.dart';
import '../widgets/async_view.dart';
import '../widgets/cloudflare_image.dart';
import '../widgets/share_button.dart';

class NewsDetailScreen extends StatefulWidget {
  const NewsDetailScreen({super.key, required this.newsId});

  final int newsId;

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final _api = NewsApi();
  late Future<News> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchNewsById(widget.newsId);
  }

  void _reload() => setState(() {
    _future = _api.fetchNewsById(widget.newsId);
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('News'),
        actions: [ShareButton(path: '/news/${widget.newsId}', title: _future.then((n) => n.title))],
      ),
      body: AsyncView<News>(
        future: _future,
        onRetry: _reload,
        onData: (context, news) {
          return ListView(
            children: [
              if (news.cloudflareId != null)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CloudflareImage(cloudflareId: news.cloudflareId),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formatGermanDate(news.date), style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.outline)),
                    const SizedBox(height: 4),
                    Text(
                      news.title,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    ),
                    const Divider(height: 32),
                    MarkdownBody(data: news.fullText, onTapLink: (_, href, _) => openUrl(href)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
