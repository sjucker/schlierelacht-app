import 'package:flutter/material.dart';

import '../api/attraction_api.dart';
import '../models/attraction.dart';
import '../models/attraction_type.dart';
import '../widgets/async_view.dart';
import '../widgets/cloudflare_image.dart';
import 'artist_detail_screen.dart';

/// Food & drink stands: the `FOOD` attractions from `/api/attraction?type=FOOD`,
/// with a client-side search over name + operator. Tapping opens the shared
/// attraction detail screen (which already renders the FOOD `operator`).
class GastroScreen extends StatefulWidget {
  const GastroScreen({super.key});

  @override
  State<GastroScreen> createState() => _GastroScreenState();
}

class _GastroScreenState extends State<GastroScreen> {
  final _api = AttractionApi();
  late Future<List<Attraction>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _api.fetchAttractions(types: {AttractionType.food});
  }

  void _reload() => setState(
      () => _future = _api.fetchAttractions(types: {AttractionType.food}));

  bool _matches(Attraction a) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return a.name.toLowerCase().contains(q) ||
        (a.operator?.toLowerCase().contains(q) ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gastro')),
      body: AsyncView<List<Attraction>>(
        future: _future,
        onRetry: _reload,
        onData: (context, all) {
          if (all.isEmpty) {
            return const Center(child: Text('Noch keine Gastro-Angebote.'));
          }
          final items = all.where(_matches).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: SearchBar(
                  hintText: 'Suchen …',
                  leading: const Icon(Icons.search),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('Keine Treffer.'))
                    : RefreshIndicator(
                        onRefresh: () async => _reload(),
                        child: ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, i) =>
                              _GastroCard(attraction: items[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GastroCard extends StatelessWidget {
  const _GastroCard({required this.attraction});

  final Attraction attraction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final image = attraction.mainImage;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ArtistDetailScreen(externalId: attraction.externalId),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: CloudflareImage(cloudflareId: image?.cloudflareId),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      attraction.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (attraction.operator != null &&
                        attraction.operator!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        attraction.operator!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}
