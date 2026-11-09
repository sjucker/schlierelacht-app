import 'package:flutter/material.dart';

import '../api/download_api.dart';
import '../models/download.dart';
import '../utils/external_links.dart';
import '../utils/formatting.dart';
import '../widgets/async_view.dart';

/// Public downloads grouped by category (website: `downloads.vue`). Tapping a
/// file opens it in the browser, which downloads or previews it.
class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final _api = DownloadApi();
  late Future<List<Download>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchDownloads();
  }

  void _reload() => setState(() => _future = _api.fetchDownloads());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: AsyncView<List<Download>>(
        future: _future,
        onRetry: _reload,
        onData: (context, downloads) {
          if (downloads.isEmpty) {
            return const Center(child: Text('Zurzeit keine Downloads.'));
          }
          final byCategory = <DownloadCategory, List<Download>>{};
          for (final d in downloads) {
            byCategory.putIfAbsent(d.category, () => []).add(d);
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                // Enum declaration order == the website's category order.
                for (final category in DownloadCategory.values)
                  if (byCategory[category] case final items?) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                      child: Text(
                        category.label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    for (final item in items)
                      ListTile(
                        leading: Icon(Icons.insert_drive_file_outlined,
                            color: theme.colorScheme.primary),
                        title: Text(item.description),
                        subtitle: Text(
                            '${fileExtension(item.filename)} · ${formatFileSize(item.filesize)}'),
                        trailing: const Icon(Icons.download_outlined),
                        onTap: () => openUrl(DownloadApi.fileUrl(item.id)),
                      ),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}
