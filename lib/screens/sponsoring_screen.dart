import 'package:flutter/material.dart';

import '../api/sponsoring_api.dart';
import '../models/sponsoring.dart';
import '../utils/external_links.dart';
import '../widgets/async_view.dart';
import '../widgets/cloudflare_image.dart';

typedef _SponsorData = ({List<Sponsoring> sponsors, List<SponsoringTypeInfo> types});

/// Sponsors grouped by tier (website: `sponsoren.vue`). Tiers come in the
/// website's order with their titles from `/api/v1/sponsoring/type`; each is a
/// section of logo tiles, except Gönner, which are listed by name. Tapping a
/// sponsor opens its website.
class SponsoringScreen extends StatefulWidget {
  const SponsoringScreen({super.key});

  @override
  State<SponsoringScreen> createState() => _SponsoringScreenState();
}

class _SponsoringScreenState extends State<SponsoringScreen> {
  final _api = SponsoringApi();
  late Future<_SponsorData> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  // Both endpoints feed the grouped layout, so wait for both.
  Future<_SponsorData> _fetch() async {
    final (sponsors, types) = await (_api.fetchSponsorings(), _api.fetchTypes()).wait;
    return (sponsors: sponsors, types: types);
  }

  void _reload() => setState(() {
    _future = _fetch();
  });

  /// Pull-to-refresh: the indicator spins until the new data is in, while
  /// the current list stays on screen (see [AsyncView]).
  Future<void> _refresh() {
    _reload();
    return settled(_future);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sponsoren')),
      body: AsyncView<_SponsorData>(
        future: _future,
        onRetry: _reload,
        onData: (context, data) {
          final byType = <SponsoringType, List<Sponsoring>>{};
          for (final s in data.sponsors) {
            byType.putIfAbsent(s.type, () => []).add(s);
          }
          final titles = {for (final t in data.types) t.type: t.description};
          // Enum declaration order == the website's TYPE_ORDER.
          final orderedTypes = SponsoringType.values.where(byType.containsKey).toList();
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [for (final type in orderedTypes) _SponsorSection(title: titles[type] ?? type.label, type: type, sponsors: byType[type]!)],
            ),
          );
        },
      ),
    );
  }
}

class _SponsorSection extends StatelessWidget {
  const _SponsorSection({required this.title, required this.type, required this.sponsors});

  final String title;
  final SponsoringType type;
  final List<Sponsoring> sponsors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, letterSpacing: 1.5),
          ),
        ),
        if (type == SponsoringType.goenner)
          // Gönner: names only, linked when they have a URL.
          for (final sponsor in sponsors)
            ListTile(
              dense: true,
              title: Text(
                sponsor.name,
                style: sponsor.url == null ? null : TextStyle(color: theme.colorScheme.primary, decoration: TextDecoration.underline),
              ),
              onTap: sponsor.url == null ? null : () => openUrl(sponsor.url),
            )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [for (final sponsor in sponsors) _SponsorTile(sponsor: sponsor)],
            ),
          ),
      ],
    );
  }
}

class _SponsorTile extends StatelessWidget {
  const _SponsorTile({required this.sponsor});

  final Sponsoring sponsor;

  @override
  Widget build(BuildContext context) {
    // Sponsor logos come on a white background (not transparent), so the card
    // is white too and blends with the logo.
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: sponsor.url == null ? null : () => openUrl(sponsor.url),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: sponsor.cloudflareId != null
              ? CloudflareImage(cloudflareId: sponsor.cloudflareId, fit: BoxFit.contain)
              : Center(
                  child: Text(
                    sponsor.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black87),
                  ),
                ),
        ),
      ),
    );
  }
}
