import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../api/attraction_api.dart';
import '../models/attraction.dart';
import '../models/programm_entry.dart';
import '../utils/formatting.dart';
import '../widgets/async_view.dart';
import '../widgets/cloudflare_image.dart';
import '../widgets/favorite_button.dart';

class ArtistDetailScreen extends StatefulWidget {
  const ArtistDetailScreen({super.key, required this.externalId});

  final String externalId;

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  final _api = AttractionApi();
  late Future<Attraction> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchAttraction(widget.externalId);
  }

  void _reload() => setState(() => _future = _api.fetchAttraction(widget.externalId));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Programm'),
        actions: [FavoriteButton(externalId: widget.externalId)],
      ),
      body: AsyncView<Attraction>(
        future: _future,
        onRetry: _reload,
        onData: (context, artist) {
          final main = artist.mainImage;
          final sortedProgramm = [...artist.programm]
            ..sort((a, b) {
              final d = a.fromDate.compareTo(b.fromDate);
              if (d != 0) return d;
              return (a.fromTime ?? '').compareTo(b.fromTime ?? '');
            });
          return ListView(
            children: [
              if (main != null)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CloudflareImage(cloudflareId: main.cloudflareId),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artist.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (artist.description.isNotEmpty) ...[
                      const Divider(height: 32),
                      MarkdownBody(data: artist.description),
                    ],
                    if (sortedProgramm.isNotEmpty) ...[
                      const Divider(height: 32),
                      Text(
                        'Programm',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      for (final entry in sortedProgramm)
                        _ProgrammRow(entry: entry),
                    ],
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

class _ProgrammRow extends StatelessWidget {
  const _ProgrammRow({required this.entry});

  final ProgrammEntry entry;

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Builds the "when" line, e.g.
  ///   "Mittwoch, 27.06.2026"                     (date only)
  ///   "Mittwoch, 27.06.2026 · 18:00"             (with fromTime)
  ///   "Mittwoch, 27.06.2026 · 18:00 – 20:00"     (with toTime, same day)
  ///   "Mittwoch, 27.06.2026 · 18:00 – Freitag, 29.06.2026 · 20:00" (spanning days)
  static String _formatWhen(ProgrammEntry entry) {
    final fromTime = formatTime(entry.fromTime);
    final toTime = formatTime(entry.toTime);
    final showToDate =
        entry.toDate != null && !_isSameDay(entry.toDate!, entry.fromDate);

    var from = formatGermanDate(entry.fromDate);
    if (fromTime.isNotEmpty) from = '$from · $fromTime';

    var to = '';
    if (showToDate) {
      to = formatGermanDate(entry.toDate!);
      if (toTime.isNotEmpty) to = '$to · $toTime';
    } else if (toTime.isNotEmpty) {
      to = toTime;
    }

    return to.isEmpty ? from : '$from – $to';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final when = _formatWhen(entry);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.event, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(when, style: theme.textTheme.bodyMedium),
                Text(
                  entry.location.name,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
