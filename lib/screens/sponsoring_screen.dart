import 'package:flutter/material.dart';

import '../api/sponsoring_api.dart';
import '../models/sponsoring.dart';
import '../utils/external_links.dart';
import '../widgets/async_view.dart';
import '../widgets/cloudflare_image.dart';

/// Sponsors grouped by tier (`SponsoringType`), each a labelled section of logo
/// tiles. Tapping a logo opens the sponsor's website.
class SponsoringScreen extends StatefulWidget {
  const SponsoringScreen({super.key});

  @override
  State<SponsoringScreen> createState() => _SponsoringScreenState();
}

class _SponsoringScreenState extends State<SponsoringScreen> {
  final _api = SponsoringApi();
  late Future<List<Sponsoring>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchSponsorings();
  }

  void _reload() => setState(() => _future = _api.fetchSponsorings());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sponsoren')),
      body: AsyncView<List<Sponsoring>>(
        future: _future,
        onRetry: _reload,
        onData: (context, sponsors) {
          if (sponsors.isEmpty) {
            return const Center(child: Text('Noch keine Sponsoren.'));
          }
          // Keep the enum's declared tier order.
          final sections = <SponsoringType, List<Sponsoring>>{};
          for (final s in sponsors) {
            sections.putIfAbsent(s.type, () => []).add(s);
          }
          final orderedTypes = SponsoringType.values
              .where((t) => sections.containsKey(t))
              .toList();
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                for (final type in orderedTypes)
                  _SponsorSection(type: type, sponsors: sections[type]!),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SponsorSection extends StatelessWidget {
  const _SponsorSection({required this.type, required this.sponsors});

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
            type.label.toUpperCase(),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              for (final sponsor in sponsors) _SponsorTile(sponsor: sponsor),
            ],
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: sponsor.url == null ? null : () => openUrl(sponsor.url),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: sponsor.cloudflareId != null
              ? CloudflareImage(
                  cloudflareId: sponsor.cloudflareId,
                  fit: BoxFit.contain,
                )
              : Center(
                  child: Text(
                    sponsor.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
        ),
      ),
    );
  }
}
