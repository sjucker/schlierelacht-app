import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../api/attraction_api.dart';
import '../models/attraction.dart';
import '../models/programm_entry.dart';
import '../utils/external_links.dart';
import '../utils/formatting.dart';
import '../widgets/async_view.dart';
import '../widgets/cloudflare_image.dart';
import '../widgets/favorite_button.dart';
import '../widgets/image_viewer.dart';
import 'location_detail_screen.dart';

/// Detail of one attraction — an act from the Programm, a Gastro stand or a
/// Wirtschaft/Gewerbe event (website: `AttractionDetail.vue`). Shows the main
/// image, social links, description, downloadable files, additional images and
/// the upcoming programm entries (each linking to its location).
class AttractionDetailScreen extends StatefulWidget {
  const AttractionDetailScreen({super.key, required this.externalId, this.title = 'Programm'});

  final String externalId;

  /// App-bar title: the section the attraction was opened from.
  final String title;

  @override
  State<AttractionDetailScreen> createState() => _AttractionDetailScreenState();
}

class _AttractionDetailScreenState extends State<AttractionDetailScreen> {
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
        title: Text(widget.title),
        actions: [FavoriteButton(externalId: widget.externalId)],
      ),
      body: AsyncView<Attraction>(
        future: _future,
        onRetry: _reload,
        onData: (context, attraction) {
          final main = attraction.mainImage;
          final additional = attraction.additionalImages;
          // Like the website, only what is still to come is listed.
          final upcoming = attraction.programm.where((e) => !e.past).toList()
            ..sort((a, b) {
              final d = a.fromDate.compareTo(b.fromDate);
              if (d != 0) return d;
              return (a.fromTime ?? '').compareTo(b.fromTime ?? '');
            });
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              if (main != null)
                GestureDetector(
                  onTap: () => showImageViewer(context, [main.cloudflareId]),
                  child: CloudflareImage(cloudflareId: main.cloudflareId, natural: true),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attraction.name,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    ),
                    _SocialLinks(attraction: attraction),
                    if (attraction.description.isNotEmpty) ...[
                      const Divider(height: 32),
                      MarkdownBody(data: attraction.description, onTapLink: (_, href, _) => openUrl(href)),
                    ],
                    if (attraction.files.isNotEmpty) ...[
                      const Divider(height: 32),
                      _SectionTitle('Downloads'),
                      for (final file in attraction.files)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.insert_drive_file_outlined, color: theme.colorScheme.primary),
                          title: Text(file.description),
                          subtitle: Text('${fileExtension(file.filename)} · ${formatFileSize(file.filesize)}'),
                          trailing: const Icon(Icons.download_outlined),
                          onTap: () => openUrl(AttractionApi.fileUrl(attraction.externalId, file.id)),
                        ),
                    ],
                  ],
                ),
              ),
              for (var i = 0; i < additional.length; i++)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: GestureDetector(
                      onTap: () => showImageViewer(context, additional.map((img) => img.cloudflareId).toList(), initialIndex: i),
                      child: CloudflareImage(cloudflareId: additional[i].cloudflareId, natural: true),
                    ),
                  ),
                ),
              if (upcoming.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle('Programm'),
                      for (final entry in upcoming) _ProgrammCard(entry: entry),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
  );
}

/// Website / Instagram / Facebook / YouTube buttons, for those that are set.
class _SocialLinks extends StatelessWidget {
  const _SocialLinks({required this.attraction});

  final Attraction attraction;

  @override
  Widget build(BuildContext context) {
    final links = <(String?, IconData, String)>[
      (attraction.website, Icons.language, 'Website'),
      (attraction.instagram, Icons.camera_alt_outlined, 'Instagram'),
      (attraction.facebook, Icons.facebook, 'Facebook'),
      (attraction.youtube, Icons.smart_display_outlined, 'YouTube'),
    ].where((l) => l.$1 != null && l.$1!.isNotEmpty).toList();
    if (links.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [for (final (url, icon, label) in links) ActionChip(avatar: Icon(icon, size: 18), label: Text(label), onPressed: () => openUrl(url))],
      ),
    );
  }
}

/// One upcoming appearance: when, plus the location linking to its detail.
class _ProgrammCard extends StatelessWidget {
  const _ProgrammCard({required this.entry});

  final ProgrammEntry entry;

  static bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// Builds the "when" line, e.g.
  ///   "Mittwoch, 27.06.2026"                     (date only)
  ///   "Mittwoch, 27.06.2026, 18:00"              (with fromTime)
  ///   "Mittwoch, 27.06.2026, 18:00 – 20:00"      (with toTime, same day)
  ///   "Mittwoch, 27.06.2026, 18:00 – Freitag, 29.06.2026, 20:00" (spanning days)
  static String _formatWhen(ProgrammEntry entry) {
    final fromTime = formatTime(entry.fromTime);
    final toTime = formatTime(entry.toTime);
    final showToDate = entry.toDate != null && !_isSameDay(entry.toDate!, entry.fromDate);

    var from = formatGermanDate(entry.fromDate);
    if (fromTime.isNotEmpty) from = '$from, $fromTime';

    var to = '';
    if (showToDate) {
      to = formatGermanDate(entry.toDate!);
      if (toTime.isNotEmpty) to = '$to, $toTime';
    } else if (toTime.isNotEmpty) {
      to = toTime;
    }

    return to.isEmpty ? from : '$from – $to';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.event, color: theme.colorScheme.primary),
        title: Text(_formatWhen(entry)),
        subtitle: Text(
          entry.location.name,
          style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LocationDetailScreen(externalId: entry.location.externalId))),
      ),
    );
  }
}
