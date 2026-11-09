import 'package:flutter/material.dart';

import '../api/attraction_api.dart';
import '../models/attraction.dart';
import '../models/attraction_type.dart';
import '../widgets/async_view.dart';
import '../widgets/cloudflare_image.dart';
import 'attraction_detail_screen.dart';

/// Food & drink stands (website: `gastro/index.vue`): the `FOOD` attractions
/// from `/api/v1/attraction?type=FOOD`, sorted by their stand number (Nr. =
/// `externalId`), with a client-side search over Nr. + name + operator.
/// Tapping opens the shared attraction detail screen.
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
    _future = _fetch();
  }

  Future<List<Attraction>> _fetch() async => (await _api.fetchAttractions(types: {AttractionType.food}))..sort((a, b) => a.externalId.compareTo(b.externalId));

  void _reload() => setState(() {
    _future = _fetch();
  });

  /// Pull-to-refresh: the indicator spins until the new data is in, while
  /// the current list stays on screen (see [AsyncView]).
  Future<void> _refresh() {
    _reload();
    return settled(_future);
  }

  bool _matches(Attraction a) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return '${a.externalId} ${a.name} ${a.operator ?? ''}'.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gastro')),
      body: AsyncView<List<Attraction>>(
        future: _future,
        onRetry: _reload,
        onData: (context, all) {
          final items = all.where(_matches).toList();
          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SearchBar(
                      hintText: 'Name, Betreiber oder Nr. suchen…',
                      leading: const Icon(Icons.search),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                ),
                if (items.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(padding: EdgeInsets.all(24), child: Text('Keine Einträge gefunden.')),
                  )
                else
                  SliverList.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) => _GastroCard(attraction: items[i]),
                  ),
              ],
            ),
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
            builder: (_) => AttractionDetailScreen(externalId: attraction.externalId, section: AttractionSection.gastro),
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: 96, height: 96, child: CloudflareImage(cloudflareId: image?.cloudflareId)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Nr. ${attraction.externalId}', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
                    Text(
                      attraction.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
                    ),
                    if (attraction.operator != null && attraction.operator!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(attraction.operator!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                    ],
                  ],
                ),
              ),
            ),
            const Padding(padding: EdgeInsets.only(right: 8), child: Icon(Icons.chevron_right)),
          ],
        ),
      ),
    );
  }
}
